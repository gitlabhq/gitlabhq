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

    subject { post :reset_cache, namespace_id: project.namespace, project_id: project, format: :json }

    it 'calls reset project cache service' do
      expect(ResetProjectCacheService).to receive_message_chain(:new, :execute)

      subject
    end

    context 'when service returns successfully' do
      it 'returns a success header' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when service does not return successfully' do
      before do
        allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(false)
      end

      it 'returns an error header' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
