require 'spec_helper'

describe Gitlab::Middleware::ReadOnly do
  include Rack::Test::Methods
  using RSpec::Parameterized::TableSyntax

  let(:rack_stack) do
    rack = Rack::Builder.new do
      use ActionDispatch::Session::CacheStore
      use ActionDispatch::Flash
      use ActionDispatch::ParamsParser
    end

    rack.run(subject)
    rack.to_app
  end

  let(:observe_env) do
    Module.new do
      attr_reader :env

      def call(env)
        @env = env
        super
      end
    end
  end

  let(:request) { Rack::MockRequest.new(rack_stack) }

  subject do
    described_class.new(fake_app).tap do |app|
      app.extend(observe_env)
    end
  end

  context 'normal requests to a read-only GitLab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

    before do
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    context 'whitelisted requests' do
      it 'expects a PATCH request to geo_nodes update URL to be allowed' do
        expect(Rails.application.routes).to receive(:recognize_path).and_call_original
        response = request.patch('/admin/geo_nodes/1')

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end
    end
  end
end
