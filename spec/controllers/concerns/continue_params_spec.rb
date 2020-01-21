# frozen_string_literal: true

require 'spec_helper'

describe ContinueParams do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include ContinueParams

      def request
        @request ||= Struct.new(:host, :port).new('test.host', 80)
      end
    end
  end

  subject(:controller) { controller_class.new }

  def strong_continue_params(params)
    ActionController::Parameters.new(continue: params)
  end

  it 'returns an empty hash if params are not present' do
    allow(controller).to receive(:params) do
      ActionController::Parameters.new
    end

    expect(controller.continue_params).to eq({})
  end

  it 'cleans up any params that are not allowed' do
    allow(controller).to receive(:params) do
      strong_continue_params(to: '/hello',
                             notice: 'world',
                             notice_now: '!',
                             something: 'else')
    end

    expect(controller.continue_params.keys).to contain_exactly(*%w(to notice notice_now))
  end

  it 'does not allow cross host redirection' do
    allow(controller).to receive(:params) do
      strong_continue_params(to: '//example.com')
    end

    expect(controller.continue_params[:to]).to be_nil
  end

  it 'allows redirecting to a path with querystring' do
    allow(controller).to receive(:params) do
      strong_continue_params(to: '/hello/world?query=string')
    end

    expect(controller.continue_params[:to]).to eq('/hello/world?query=string')
  end
end
