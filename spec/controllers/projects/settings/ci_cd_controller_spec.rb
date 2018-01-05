require('spec_helper')

describe Projects::Settings::CiCdController do
  let(:project) { create(:project, :public, :access_requestable) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  describe '#reset_cache' do
    before do
      sign_in(user)

      project.add_master(user)

      allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(true)
    end

    subject { post :reset_cache, namespace_id: project.namespace, project_id: project }

    it 'calls reset project cache service' do
      expect(ResetProjectCacheService).to receive_message_chain(:new, :execute)

      subject
    end

    it 'redirects to project pipelines path' do
      subject

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(project_pipelines_path(project))
    end

    context 'when service returns successfully' do
      it 'sets the flash notice variable' do
        subject

        expect(controller).to set_flash[:notice]
        expect(controller).not_to set_flash[:error]
      end
    end

    context 'when service does not return successfully' do
      before do
        allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(false)
      end

      it 'sets the flash error variable' do
        subject

        expect(controller).not_to set_flash[:notice]
        expect(controller).to set_flash[:error]
      end
    end
  end
end
