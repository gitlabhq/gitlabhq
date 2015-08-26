require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:project) { FactoryGirl.create(:project) }
  let(:gitlab_url) { GitlabCi.config.gitlab_server.url }
  let(:private_token) { Network.new.authenticate(access_token: "some_token")["private_token"] }

  let(:options) {
    {
      private_token: private_token,
      url: gitlab_url
    }
  }

  before {
    stub_gitlab_calls
  }


  describe "POST /forks" do
    let(:project_info) {
      {
        project_id: project.gitlab_id,
        project_token: project.token,
        data: {
          id:                  2,
          name_with_namespace: "Gitlab.org / Underscore",
          path_with_namespace: "gitlab-org/underscore",
          default_branch:      "master",
          ssh_url_to_repo:     "git@example.com:gitlab-org/underscore"
        }
      }
    }

    context "with valid info" do
      before do
        options.merge!(project_info)
      end

      it "should create a project with valid data" do
        post api("/forks"), options
        response.status.should == 201
        json_response['name'].should == "Gitlab.org / Underscore"
      end
    end

    context "with invalid project info" do
      before do
        options.merge!({})
      end

      it "should error with invalid data" do
        post api("/forks"), options
        response.status.should == 400
      end
    end
  end
end
