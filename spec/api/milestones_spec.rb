require 'spec_helper'

describe Gitlab::API do
  let(:user) { Factory :user }
  let!(:project) { Factory :project, owner: user }
  let!(:milestone) { Factory :milestone, project: project }

  before { project.add_access(user, :read) }
  before { return pending }

  describe "GET /projects/:id/milestones" do
    it "should return project milestones" do
      get "#{api_prefix}/projects/#{project.code}/milestones?private_token=#{user.private_token}"
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == milestone.title
    end
  end

  describe "GET /projects/:id/milestones/:milestone_id" do
    it "should return a project milestone by id" do
      get "#{api_prefix}/projects/#{project.code}/milestones/#{milestone.id}?private_token=#{user.private_token}"
      response.status.should == 200
      json_response['title'].should == milestone.title
    end
  end

  describe "POST /projects/:id/milestones" do
    it "should create a new project milestone" do
      post "#{api_prefix}/projects/#{project.code}/milestones?private_token=#{user.private_token}",
        title: 'new milestone'
      response.status.should == 201
      json_response['title'].should == 'new milestone'
      json_response['description'].should be_nil
    end
  end

  describe "PUT /projects/:id/milestones/:milestone_id" do
    it "should update a project milestone" do
      put "#{api_prefix}/projects/#{project.code}/milestones/#{milestone.id}?private_token=#{user.private_token}",
        title: 'updated title'
      response.status.should == 200
      json_response['title'].should == 'updated title'
    end
  end
end
