# frozen_string_literal: true

require "spec_helper"

# Based on https://github.com/rails/rails/pull/45115/files#diff-35ef6d1bd8b8d3b037ec819a704cd78db55db916a57abfc2859882826fc679b6
RSpec.describe ContentSecurityPolicyPatch, feature_category: :shared do
  include Rack::Test::Methods

  let(:routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        # Using Testing module defined below
        scope module: "testing" do
          get "/", to: "policy#index"
        end
      end
    end
  end

  let(:csp) do
    ActionDispatch::ContentSecurityPolicy.new do |p|
      p.default_src -> { :self }
      p.script_src -> { :https }
    end
  end

  let(:policy_middleware) do
    Module.new do
      def self.new(app, policy)
        ->(env) do
          env["action_dispatch.content_security_policy"] = policy

          app.call(env)
        end
      end
    end
  end

  subject(:app) do
    build_app(routes) do |middleware|
      middleware.use policy_middleware, csp
      middleware.use ActionDispatch::ContentSecurityPolicy::Middleware
    end
  end

  def setup_controller
    application_controller = Class.new(ActionController::Base) do # rubocop:disable Rails/ApplicationController
      helper_method :sky_is_blue?
      def sky_is_blue?
        true
      end
    end

    policy_controller = Class.new(application_controller) do
      extend ContentSecurityPolicyPatch

      content_security_policy_with_context do |p|
        p.default_src "https://example.com"
        p.script_src "https://example.com" if helpers.sky_is_blue?
      end

      def index
        head :ok
      end
    end

    stub_const("Testing::ApplicationController", application_controller)
    stub_const("Testing::PolicyController", policy_controller)
  end

  def build_app(routes)
    stack = ActionDispatch::MiddlewareStack.new do |middleware|
      middleware.use ActionDispatch::DebugExceptions
      middleware.use ActionDispatch::ActionableExceptions
      middleware.use ActionDispatch::Callbacks
      middleware.use ActionDispatch::Cookies
      middleware.use ActionDispatch::Flash
      middleware.use Rack::MethodOverride
      middleware.use Rack::Head

      yield(middleware) if block_given?
    end

    app = stack.build(routes)

    ->(env) { app.call(env) }
  end

  it "calls helper method" do
    setup_controller

    response = get "/"

    csp_header = response.headers["Content-Security-Policy"]

    expect(csp_header).to include "default-src https://example.com"
    expect(csp_header).to include "script-src https://example.com"
  end

  it "does not emit any warnings" do
    expect { setup_controller }.not_to output.to_stderr
  end

  context "with Rails version 7.2" do
    before do
      version = Gem::Version.new("7.2.0")
      allow(Rails).to receive(:gem_version).and_return(version)
    end

    it "emits a deprecation warning" do
      expect { setup_controller }
        .to output(/Use content_security_policy instead/)
        .to_stderr
    end
  end
end
