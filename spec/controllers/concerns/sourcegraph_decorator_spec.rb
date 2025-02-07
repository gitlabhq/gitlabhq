# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SourcegraphDecorator do
  let_it_be(:enabled_user) { create(:user, sourcegraph_enabled: true) }
  let_it_be(:disabled_user) { create(:user, sourcegraph_enabled: false) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:internal_project) { create(:project, :internal) }

  let(:sourcegraph_url) { 'http://sourcegraph.gitlab.com' }
  let(:sourcegraph_enabled) { true }
  let(:sourcegraph_public_only) { false }
  let(:format) { :html }
  let(:user) { enabled_user }
  let(:project) { internal_project }

  controller(ApplicationController) do
    include SourcegraphDecorator

    def index
      head :ok
    end
  end

  before do
    stub_application_setting(sourcegraph_url: sourcegraph_url, sourcegraph_enabled: sourcegraph_enabled, sourcegraph_public_only: sourcegraph_public_only)

    allow(controller).to receive(:project).and_return(project)

    Gon.clear

    sign_in user if user
  end

  subject do
    get :index, format: format

    Gon.sourcegraph
  end

  shared_examples 'enabled' do
    it { is_expected.to eq({ url: sourcegraph_url }) }
  end

  shared_examples 'disabled' do
    it { is_expected.to be_nil }
  end

  context 'with application enabled, and user enabled' do
    it_behaves_like 'enabled'
  end

  context 'with admin settings disabled' do
    let(:sourcegraph_enabled) { false }

    it_behaves_like 'disabled'
  end

  context 'with public only' do
    let(:sourcegraph_public_only) { true }

    context 'with internal project' do
      let(:project) { internal_project }

      it_behaves_like 'disabled'
    end

    context 'with public project' do
      let(:project) { public_project }

      it_behaves_like 'enabled'
    end
  end

  context 'with user disabled' do
    let(:user) { disabled_user }

    it_behaves_like 'disabled'
  end

  context 'with no user' do
    let(:user) { nil }

    it_behaves_like 'disabled'
  end

  context 'with non-html format' do
    let(:format) { :json }

    it_behaves_like 'disabled'
  end
end
