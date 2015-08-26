require 'spec_helper'

describe API::API do
  include ApiHelpers

  describe 'POST /projects/:project_id/refs/:ref/trigger' do
    let!(:trigger_token) { 'secure token' }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:project2) { FactoryGirl.create(:project) }
    let!(:trigger) { FactoryGirl.create(:trigger, project: project, token: trigger_token) }
    let(:options) {
      {
        token: trigger_token
      }
    }

    context 'Handles errors' do
      it 'should return bad request if token is missing' do
        post api("/projects/#{project.id}/refs/master/trigger")
        response.status.should == 400
      end

      it 'should return not found if project is not found' do
        post api('/projects/0/refs/master/trigger'), options
        response.status.should == 404
      end

      it 'should return unauthorized if token is for different project' do
        post api("/projects/#{project2.id}/refs/master/trigger"), options
        response.status.should == 401
      end
    end

    context 'Have a commit' do
      before do
        @commit = FactoryGirl.create(:commit, project: project)
      end

      it 'should create builds' do
        post api("/projects/#{project.id}/refs/master/trigger"), options
        response.status.should == 201
        @commit.builds.reload
        @commit.builds.size.should == 2
      end

      it 'should return bad request with no builds created if there\'s no commit for that ref' do
        post api("/projects/#{project.id}/refs/other-branch/trigger"), options
        response.status.should == 400
        json_response['message'].should == 'No builds created'
      end

      context 'Validates variables' do
        let(:variables) {
          {'TRIGGER_KEY' => 'TRIGGER_VALUE'}
        }

        it 'should validate variables to be a hash' do
          post api("/projects/#{project.id}/refs/master/trigger"), options.merge(variables: 'value')
          response.status.should == 400
          json_response['message'].should == 'variables needs to be a hash'
        end

        it 'should validate variables needs to be a map of key-valued strings' do
          post api("/projects/#{project.id}/refs/master/trigger"), options.merge(variables: {key: %w(1 2)})
          response.status.should == 400
          json_response['message'].should == 'variables needs to be a map of key-valued strings'
        end

        it 'create trigger request with variables' do
          post api("/projects/#{project.id}/refs/master/trigger"), options.merge(variables: variables)
          response.status.should == 201
          @commit.builds.reload
          @commit.builds.first.trigger_request.variables.should == variables
        end
      end
    end
  end
end
