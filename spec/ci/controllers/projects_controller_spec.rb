require "spec_helper"

describe ProjectsController do
  before do
    @project = FactoryGirl.create :project
  end

  describe "POST #build" do
    it 'should respond 200 if params is ok' do
      post :build, id: @project.id,
        ref: 'master',
        before: '2aa371379db71ac89ae20843fcff3b3477cf1a1d',
        after: '1c8a9df454ef68c22c2a33cca8232bb50849e5c5',
        token: @project.token,
        ci_yaml_file: gitlab_ci_yaml,
        commits: [ { message: "Message" } ]


      expect(response).to be_success
      expect(response.code).to eq('201')
    end

    it 'should respond 400 if push about removed branch' do
      post :build, id: @project.id,
        ref: 'master',
        before: '2aa371379db71ac89ae20843fcff3b3477cf1a1d',
        after: '0000000000000000000000000000000000000000',
        token: @project.token,
        ci_yaml_file: gitlab_ci_yaml

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
    let(:project_dump) { YAML.load File.read(Rails.root.join('spec/support/gitlab_stubs/raw_project.yml')) }
    let(:gitlab_url) { GitlabCi.config.gitlab_server.url }

    let (:user_data) do
      data = JSON.parse File.read(Rails.root.join('spec/support/gitlab_stubs/user.json'))
      data.merge("url" => gitlab_url)
    end

    let(:user) do
      User.new(user_data)
    end

    it "creates project" do
      allow(controller).to receive(:reset_cache) { true }
      allow(controller).to receive(:current_user) { user }
      Network.any_instance.stub(:enable_ci).and_return(true)
      Network.any_instance.stub(:project_hooks).and_return(true)

      post :create, { project: JSON.dump(project_dump.to_h) }.with_indifferent_access

      expect(response.code).to eq('302')
      expect(assigns(:project)).not_to be_a_new(Project)
    end

    it "shows error" do
      allow(controller).to receive(:reset_cache) { true }
      allow(controller).to receive(:current_user) { user }
      User.any_instance.stub(:can_manage_project?).and_return(false)

      post :create, { project: JSON.dump(project_dump.to_h) }.with_indifferent_access

      expect(response.code).to eq('302')
      expect(flash[:alert]).to include("You have to have at least master role to enable CI for this project")
    end
  end

  describe "GET /gitlab" do
    let(:gitlab_url) { GitlabCi.config.gitlab_server.url }

    let (:user_data) do
      data = JSON.parse File.read(Rails.root.join('spec/support/gitlab_stubs/user.json'))
      data.merge("url" => gitlab_url)
    end

    let(:user) do
      User.new(user_data)
    end

    it "searches projects" do
      allow(controller).to receive(:reset_cache) { true }
      allow(controller).to receive(:current_user) { user }
      Network.any_instance.should_receive(:projects).with(hash_including(search: 'str'), :authorized)

      xhr :get, :gitlab, { search: "str", format: "js" }.with_indifferent_access

      expect(response).to be_success
      expect(response.code).to eq('200')
    end
  end
end
