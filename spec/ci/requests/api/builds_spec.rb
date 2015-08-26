require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:runner) { FactoryGirl.create(:runner, tag_list: ["mysql", "ruby"]) }
  let(:project) { FactoryGirl.create(:project) }

  describe "Builds API for runners" do
    let(:shared_runner) { FactoryGirl.create(:runner, token: "SharedRunner") }
    let(:shared_project) { FactoryGirl.create(:project, name: "SharedProject") }

    before do
      FactoryGirl.create :runner_project, project_id: project.id, runner_id: runner.id
    end

    describe "POST /builds/register" do
      it "should start a build" do
        commit = FactoryGirl.create(:commit, project: project)
        commit.create_builds
        build = commit.builds.first

        post api("/builds/register"), token: runner.token, info: {platform: :darwin}

        response.status.should == 201
        json_response['sha'].should == build.sha
        runner.reload.platform.should == "darwin"
      end

      it "should return 404 error if no pending build found" do
        post api("/builds/register"), token: runner.token

        response.status.should == 404
      end

      it "should return 404 error if no builds for specific runner" do
        commit = FactoryGirl.create(:commit, project: shared_project)
        FactoryGirl.create(:build, commit: commit, status: 'pending' )

        post api("/builds/register"), token: runner.token

        response.status.should == 404
      end

      it "should return 404 error if no builds for shared runner" do
        commit = FactoryGirl.create(:commit, project: project)
        FactoryGirl.create(:build, commit: commit, status: 'pending' )

        post api("/builds/register"), token: shared_runner.token

        response.status.should == 404
      end

      it "returns options" do
        commit = FactoryGirl.create(:commit, project: project)
        commit.create_builds

        post api("/builds/register"), token: runner.token, info: {platform: :darwin}

        response.status.should == 201
        json_response["options"].should == {"image" => "ruby:2.1", "services" => ["postgres"]}
      end

      it "returns variables" do
        commit = FactoryGirl.create(:commit, project: project)
        commit.create_builds
        project.variables << Variable.new(key: "SECRET_KEY", value: "secret_value")

        post api("/builds/register"), token: runner.token, info: {platform: :darwin}

        response.status.should == 201
        json_response["variables"].should == [
          {"key" => "DB_NAME", "value" => "postgres", "public" => true},
          {"key" => "SECRET_KEY", "value" => "secret_value", "public" => false},
        ]
      end

      it "returns variables for triggers" do
        trigger = FactoryGirl.create(:trigger, project: project)
        commit = FactoryGirl.create(:commit, project: project)

        trigger_request = FactoryGirl.create(:trigger_request_with_variables, commit: commit, trigger: trigger)
        commit.create_builds(trigger_request)
        project.variables << Variable.new(key: "SECRET_KEY", value: "secret_value")

        post api("/builds/register"), token: runner.token, info: {platform: :darwin}

        response.status.should == 201
        json_response["variables"].should == [
          {"key" => "DB_NAME", "value" => "postgres", "public" => true},
          {"key" => "SECRET_KEY", "value" => "secret_value", "public" => false},
          {"key" => "TRIGGER_KEY", "value" => "TRIGGER_VALUE", "public" => false},
        ]
      end
    end

    describe "PUT /builds/:id" do
      let(:commit) { FactoryGirl.create(:commit, project: project)}
      let(:build) { FactoryGirl.create(:build, commit: commit, runner_id: runner.id) }

      it "should update a running build" do
        build.run!
        put api("/builds/#{build.id}"), token: runner.token
        response.status.should == 200
      end

      it 'Should not override trace information when no trace is given' do
        build.run!
        build.update!(trace: 'hello_world')
        put api("/builds/#{build.id}"), token: runner.token
        expect(build.reload.trace).to eq 'hello_world'
      end
    end
  end
end
