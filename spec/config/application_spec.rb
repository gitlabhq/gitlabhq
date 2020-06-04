# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Application do # rubocop:disable RSpec/FilePath
  using RSpec::Parameterized::TableSyntax

  filtered_param = ActiveSupport::ParameterFilter::FILTERED

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
        '/?private_token=secret'                 | { 'private_token' => filtered_param }
        '/?mixed=1&private_token=secret'         | { 'mixed' => '1', 'private_token' => filtered_param }
        '/?note=secret&noteable=1&prefix_note=2' | { 'note' => filtered_param, 'noteable' => '1', 'prefix_note' => '2' }
        '/?note[note]=secret&target_type=1'      | { 'note' => filtered_param, 'target_type' => '1' }
        '/?safe[note]=secret&target_type=1'      | { 'safe' => { 'note' => filtered_param }, 'target_type' => '1' }
      end

      with_them do
        it { expect(request_for_url(input_url).filtered_parameters).to eq(output_query) }
      end
    end
  end
end
