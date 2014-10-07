require 'spec_helper'

include RepoHelpers

describe Projects::EditTreeController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :developer]
  end

  describe 'GET show' do
    it 'responds with success if branch / path pair exists' do
      get :show, project_id: project.to_param, id: existing_path_id

      assert_response :success
    end

    it 'responds with not found if branch / path pair does not exist' do
      get :show, project_id: project.to_param, id: inexistent_path_id

      assert_response :not_found
    end
  end
end
