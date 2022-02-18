# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AvatarsController do
  describe 'GET #show' do
    let_it_be(:project) { create(:project, :public, :repository) }

    before do
      controller.instance_variable_set(:@project, project)
    end

    subject { get :show, params: { namespace_id: project.namespace, project_id: project.path } }

    context 'when repository has no avatar' do
      it 'shows 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when repository has an avatar' do
      before do
        allow(project).to receive(:avatar_in_git).and_return(filepath)
      end

      context 'when the avatar is stored in the repository' do
        let(:filepath) { 'files/images/logo-white.png' }

        it 'sends the avatar' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.header['Content-Disposition']).to eq('inline')
          expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
          expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
        end

        it 'sets appropriate caching headers' do
          sign_in(project.first_owner)
          subject

          expect(response.cache_control[:public]).to eq(true)
          expect(response.cache_control[:max_age]).to eq(60)
          expect(response.cache_control[:no_store]).to be_nil
        end

        it_behaves_like 'project cache control headers'
      end

      context 'when the avatar is stored in lfs' do
        let(:filename) { 'lfs_object.iso' }
        let(:filepath) { "files/lfs/#{filename}" }

        it_behaves_like 'a controller that can serve LFS files'
        it_behaves_like 'project cache control headers'
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:project) { create(:project, :repository, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

    before do
      sign_in(project.first_owner)
    end

    it 'removes avatar from DB by calling destroy' do
      delete :destroy, params: { namespace_id: project.namespace.path, project_id: project.path }

      expect(response).to redirect_to(edit_project_path(project, anchor: 'js-general-project-settings'))
      expect(project.avatar.present?).to be_falsey
      expect(project).to be_valid
    end
  end
end
