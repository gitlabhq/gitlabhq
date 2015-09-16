require "spec_helper"

describe Ci::ProjectsController do
  before do
    @project = FactoryGirl.create :ci_project
  end

  describe "POST #build" do
    it 'should respond 200 if params is ok' do
      post :build, {
        id:           @project.id,
        ref:          'master',
        before:       '2aa371379db71ac89ae20843fcff3b3477cf1a1d',
        after:        '1c8a9df454ef68c22c2a33cca8232bb50849e5c5',
        token:        @project.token,
        ci_yaml_file: gitlab_ci_yaml,
        commits:      [ { message: "Message" } ]
      }

      expect(response).to be_success
      expect(response.code).to eq('201')
    end

    it 'should respond 400 if push about removed branch' do
      post :build, {
        id:           @project.id,
        ref:          'master',
        before:       '2aa371379db71ac89ae20843fcff3b3477cf1a1d',
        after:        '0000000000000000000000000000000000000000',
        token:        @project.token,
        ci_yaml_file: gitlab_ci_yaml
      }

      expect(response).not_to be_success
      expect(response.code).to eq('400')
    end

    it 'should respond 400 if some params missed' do
      post :build, id: @project.id, token: @project.token, ci_yaml_file: gitlab_ci_yaml
      expect(response).not_to be_success
      expect(response.code).to eq('400')
    end

    it 'should respond 403 if token is wrong' do
      post :build, id: @project.id, token: 'invalid-token'
      expect(response).not_to be_success
      expect(response.code).to eq('403')
    end
  end

  describe "POST /projects" do
    let(:project_dump) { OpenStruct.new({ id: @project.gitlab_id }) }

    let(:user) do
      create(:user)
    end

    before do
      sign_in(user)
    end

    it "creates project" do
      post :create, { project: JSON.dump(project_dump.to_h) }.with_indifferent_access

      expect(response.code).to eq('302')
      expect(assigns(:project)).not_to be_a_new(Ci::Project)
    end

    it "shows error" do
      post :create, { project: JSON.dump(project_dump.to_h) }.with_indifferent_access

      expect(response.code).to eq('302')
      expect(flash[:alert]).to include("You have to have at least master role to enable CI for this project")
    end
  end

  describe "GET /gitlab" do
    let(:user) do
      create(:user)
    end

    before do
      sign_in(user)
    end

    it "searches projects" do
      xhr :get, :gitlab, { search: "str", format: "js" }.with_indifferent_access

      expect(response).to be_success
      expect(response.code).to eq('200')
    end
  end
end
