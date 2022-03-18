# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tracings Content Security Policy' do
  include ContentSecurityPolicyHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject { response_headers['Content-Security-Policy'] }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  context 'when there is no global config' do
    before do
      setup_csp_for_controller(Projects::TracingsController)
    end

    it 'does not add CSP directives' do
      visit project_tracing_path(project)

      is_expected.to be_blank
    end
  end

  context 'when a global CSP config exists' do
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.frame_src 'https://global-policy.com'
      end

      setup_existing_csp_for_controller(Projects::TracingsController, csp)
    end

    context 'when external_url is set' do
      let!(:project_tracing_setting) { create(:project_tracing_setting, project: project) }

      it 'overwrites frame-src' do
        visit project_tracing_path(project)

        is_expected.to eq("frame-src https://example.com")
      end
    end

    context 'when external_url is not set' do
      it 'uses global policy' do
        visit project_tracing_path(project)

        is_expected.to eq("frame-src https://global-policy.com")
      end
    end
  end
end
