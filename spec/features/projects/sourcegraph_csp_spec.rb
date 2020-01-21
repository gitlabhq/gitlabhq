# frozen_string_literal: true

require 'spec_helper'

describe 'Sourcegraph Content Security Policy' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }
  let_it_be(:default_csp_values) { "'self' https://some-cdn.test" }
  let_it_be(:sourcegraph_url) { 'https://sourcegraph.test' }
  let(:sourcegraph_enabled) { true }

  subject do
    visit project_blob_path(project, File.join('master', 'README.md'))

    response_headers['Content-Security-Policy']
  end

  before do
    allow(Gitlab::CurrentSettings).to receive(:sourcegraph_url).and_return(sourcegraph_url)
    allow(Gitlab::CurrentSettings).to receive(:sourcegraph_enabled).and_return(sourcegraph_enabled)

    sign_in(user)
  end

  shared_context 'csp config' do |csp_rule|
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.send(csp_rule, default_csp_values) if csp_rule
      end

      expect_next_instance_of(Projects::BlobController) do |controller|
        expect(controller).to receive(:current_content_security_policy).and_return(csp)
      end
    end
  end

  context 'when no CSP config' do
    include_context 'csp config', nil

    it 'does not add CSP directives' do
      is_expected.to be_blank
    end
  end

  describe 'when a CSP config exists for connect-src' do
    include_context 'csp config', :connect_src

    context 'when sourcegraph enabled' do
      it 'appends to connect-src' do
        is_expected.to eql("connect-src #{default_csp_values} #{sourcegraph_url}")
      end
    end

    context 'when sourcegraph disabled' do
      let(:sourcegraph_enabled) { false }

      it 'keeps original connect-src' do
        is_expected.to eql("connect-src #{default_csp_values}")
      end
    end
  end

  describe 'when a CSP config exists for default-src but not connect-src' do
    include_context 'csp config', :default_src

    context 'when sourcegraph enabled' do
      it 'uses default-src values in connect-src' do
        is_expected.to eql("default-src #{default_csp_values}; connect-src #{default_csp_values} #{sourcegraph_url}")
      end
    end

    context 'when sourcegraph disabled' do
      let(:sourcegraph_enabled) { false }

      it 'does not add connect-src' do
        is_expected.to eql("default-src #{default_csp_values}")
      end
    end
  end

  describe 'when a CSP config exists for font-src but not connect-src' do
    include_context 'csp config', :font_src

    context 'when sourcegraph enabled' do
      it 'uses default-src values in connect-src' do
        is_expected.to eql("font-src #{default_csp_values}; connect-src #{sourcegraph_url}")
      end
    end

    context 'when sourcegraph disabled' do
      let(:sourcegraph_enabled) { false }

      it 'does not add connect-src' do
        is_expected.to eql("font-src #{default_csp_values}")
      end
    end
  end
end
