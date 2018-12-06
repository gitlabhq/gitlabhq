require 'spec_helper'

describe Projects::AvatarsController do
  let(:project) { create(:project, :repository) }

  before do
    controller.instance_variable_set(:@project, project)
  end

  describe 'GET #show' do
    subject { get :show, namespace_id: project.namespace, project_id: project }

    context 'when repository has no avatar' do
      it 'shows 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when repository has an avatar' do
      before do
        allow(project).to receive(:avatar_in_git).and_return(filepath)
      end

      context 'when the avatar is stored in the repository' do
        let(:filepath) { 'files/images/logo-white.png' }

        context 'when feature flag workhorse_set_content_type is' do
          before do
            stub_feature_flags(workhorse_set_content_type: flag_value)
          end

          context 'enabled' do
            let(:flag_value) { true }

            it 'sends the avatar' do
              subject

              expect(response).to have_gitlab_http_status(200)
              expect(response.header['Content-Disposition']).to eq('inline')
              expect(response.header['Content-Type']).to eq 'image/png'
              expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
              expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
            end
          end

          context 'disabled' do
            let(:flag_value) { false }

            it 'sends the avatar' do
              subject

              expect(response).to have_gitlab_http_status(200)
              expect(response.header['Content-Type']).to eq('image/png')
              expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
              expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq nil
            end
          end
        end
      end

      context 'when the avatar is stored in lfs' do
        it_behaves_like 'repository lfs file load' do
          let(:filename) { 'lfs_object.iso' }
          let(:filepath) { "files/lfs/#{filename}" }
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'removes avatar from DB by calling destroy' do
      delete :destroy, namespace_id: project.namespace.id, project_id: project.id

      expect(project.avatar.present?).to be_falsey
      expect(project).to be_valid
    end
  end
end
