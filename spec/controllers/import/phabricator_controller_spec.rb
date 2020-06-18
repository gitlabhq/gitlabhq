# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PhabricatorController do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  describe 'GET #new' do
    subject { get :new }

    context 'when the import source is not available' do
      before do
        stub_feature_flags(phabricator_import: true)
        stub_application_setting(import_sources: [])
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when the feature is disabled' do
      before do
        stub_feature_flags(phabricator_import: false)
        stub_application_setting(import_sources: ['phabricator'])
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when the import is available' do
      before do
        stub_feature_flags(phabricator_import: true)
        stub_application_setting(import_sources: ['phabricator'])
      end

      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  describe 'POST #create' do
    subject(:post_create) { post :create, params: params }

    context 'with valid params' do
      let(:params) do
        { path: 'phab-import',
          name: 'Phab import',
          phabricator_server_url: 'https://phabricator.example.com',
          api_token: 'hazaah',
          namespace_id: current_user.namespace_id }
      end

      it 'creates a project to import', :sidekiq_might_not_need_inline do
        expect_next_instance_of(Gitlab::PhabricatorImport::Importer) do |importer|
          expect(importer).to receive(:execute)
        end

        expect { post_create }.to change { current_user.namespace.projects.reload.size }.from(0).to(1)

        expect(current_user.namespace.projects.last).to be_import
      end
    end

    context 'when an import param is missing' do
      let(:params) do
        { path: 'phab-import',
          name: 'Phab import',
          phabricator_server_url: nil,
          api_token: 'hazaah',
          namespace_id: current_user.namespace_id }
      end

      it 'does not create the project' do
        expect { post_create }.not_to change { current_user.namespace.projects.reload.size }
      end
    end

    context 'when a project param is missing' do
      let(:params) do
        { phabricator_server_url: 'https://phabricator.example.com',
          api_token: 'hazaah',
          namespace_id: current_user.namespace_id }
      end

      it 'does not create the project' do
        expect { post_create }.not_to change { current_user.namespace.projects.reload.size }
      end
    end

    it_behaves_like 'project import rate limiter'
  end
end
