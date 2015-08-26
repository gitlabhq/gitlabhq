require 'spec_helper'

describe API::API, 'Commits' do
  include ApiHelpers

  let(:project) { FactoryGirl.create(:project) }
  let(:commit) { FactoryGirl.create(:commit, project: project) }

  let(:options) {
    {
      project_token: project.token,
      project_id: project.id
    }
  }

  describe "GET /commits" do
    before { commit }

    it "should return commits per project" do
      get api("/commits"), options

      response.status.should == 200
      json_response.count.should == 1
      json_response.first["project_id"].should == project.id
      json_response.first["sha"].should == commit.sha
    end
  end

  describe "POST /commits" do
    let(:data) {
      {
        "before" => "95790bf891e76fee5e1747ab589903a6a1f80f22",
        "after" => "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
        "ref" => "refs/heads/master",
        "commits" => [
          {
            "id" => "b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
            "message" => "Update Catalan translation to e38cb41.",
            "timestamp" => "2011-12-12T14:27:31+02:00",
            "url" => "http://localhost/diaspora/commits/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
            "author" => {
              "name" => "Jordi Mallach",
              "email" => "jordi@softcatala.org",
            }
          }
        ],
        ci_yaml_file: gitlab_ci_yaml
      }
    }

    it "should create a build" do
      post api("/commits"), options.merge(data: data)

      response.status.should == 201
      json_response['sha'].should == "da1560886d4f094c3e6c9ef40349f7d38b5d27d7"
    end

    it "should return 400 error if no data passed" do
      post api("/commits"), options

      response.status.should == 400
      json_response['message'].should == "400 (Bad request) \"data\" not given"
    end
  end
end
