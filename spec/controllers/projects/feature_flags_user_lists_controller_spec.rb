# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::FeatureFlagsUserListsController do
  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  def request_params(extra_params = {})
    { namespace_id: project.namespace, project_id: project }.merge(extra_params)
  end

  describe 'GET #index' do
    it 'redirects when the user is unauthenticated' do
      get(:index, params: request_params)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns not found if the user does not belong to the project' do
      user = create(:user)
      sign_in(user)

      get(:index, params: request_params)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns not found for a reporter' do
      sign_in(reporter)

      get(:index, params: request_params)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'renders the new page for a developer' do
      sign_in(developer)

      get(:index, params: request_params)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET #new' do
    it 'redirects when the user is unauthenticated' do
      get(:new, params: request_params)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns not found if the user does not belong to the project' do
      user = create(:user)
      sign_in(user)

      get(:new, params: request_params)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns not found for a reporter' do
      sign_in(reporter)

      get(:new, params: request_params)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'renders the new page for a developer' do
      sign_in(developer)

      get(:new, params: request_params)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET #edit' do
    before do
      sign_in(developer)
    end

    it 'renders the edit page for a developer' do
      list = create(:operations_feature_flag_user_list, project: project)

      get(:edit, params: request_params(iid: list.iid))

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns not found with an iid that does not exist' do
      list = create(:operations_feature_flag_user_list, project: project)

      get(:edit, params: request_params(iid: list.iid + 1))

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns not found for a list belonging to a another project' do
      other_project = create(:project)
      list = create(:operations_feature_flag_user_list, project: other_project)

      get(:edit, params: request_params(iid: list.iid))

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    before do
      sign_in(developer)
    end

    it 'renders the page for a developer' do
      list = create(:operations_feature_flag_user_list, project: project)

      get(:show, params: request_params(iid: list.iid))

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns not found with an iid that does not exist' do
      list = create(:operations_feature_flag_user_list, project: project)

      get(:show, params: request_params(iid: list.iid + 1))

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns not found for a list belonging to a another project' do
      other_project = create(:project)
      list = create(:operations_feature_flag_user_list, project: other_project)

      get(:show, params: request_params(iid: list.iid))

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
