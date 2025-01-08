# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Application, feature_category: :scalability do # rubocop:disable RSpec/SpecFilePathFormat
  describe 'config.filter_parameters' do
    using RSpec::Parameterized::TableSyntax

    filtered = ActiveSupport::ParameterFilter::FILTERED

    context 'when parameters are logged' do
      describe 'rails does not leak confidential parameters' do
        def request_for_url(input_url)
          env = Rack::MockRequest.env_for(input_url)
          env['action_dispatch.parameter_filter'] = described_class.config.filter_parameters

          ActionDispatch::Request.new(env)
        end

        where(:input_url, :output_query) do
          '/'                                      | {}
          '/?safe=1'                               | { 'safe' => '1' }
          '/?token=secret'                         | { 'token' => filtered }
          '/?TOKEN=secret'                         | { 'TOKEN' => filtered }
          '/?private_token=secret'                 | { 'private_token' => filtered }
          '/?PRIVATE_TOKEN=secret'                 | { 'PRIVATE_TOKEN' => filtered }
          '/?mixed=1&private_token=secret'         | { 'mixed' => '1', 'private_token' => filtered }
          '/?note=secret&noteable=1&prefix_note=2' | { 'note' => filtered, 'noteable' => '1', 'prefix_note' => '2' }
          '/?note[note]=secret&target_type=1'      | { 'note' => filtered, 'target_type' => '1' }
          '/?safe[note]=secret&target_type=1'      | { 'safe' => { 'note' => filtered }, 'target_type' => '1' }
          '/?safe[selectedText]=secret'            | { 'safe' => { 'selectedText' => filtered } }
          '/?selectedText=secret'                  | { 'selectedText' => filtered }
          '/?query=secret'                         | { 'query' => filtered }
        end

        with_them do
          it { expect(request_for_url(input_url).filtered_parameters).to eq(output_query) }
        end
      end
    end
  end

  describe 'clear_active_connections_again initializer' do
    subject(:clear_active_connections_again) do
      described_class.initializers.find { |i| i.name == :clear_active_connections_again }
    end

    it 'is included in list of Rails initializers' do
      expect(clear_active_connections_again).to be_present
    end

    it 'is configured after set_routes_reloader_hook' do
      expect(clear_active_connections_again.after).to eq(:set_routes_reloader_hook)
    end

    describe 'functionality', :reestablished_active_record_base do
      it 'clears all connections' do
        Project.first

        clear_active_connections_again.run

        expect(ActiveRecord::Base.connection_handler.active_connections?).to eq(false)
      end
    end
  end
end
