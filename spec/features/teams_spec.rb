require 'spec_helper'

describe 'Teams' do

  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:team) { create(:user_team, owner: user) }

  before do
    team.assign_to_project(project, UserTeam.access_roles["Master"])
  end

  describe "Add member to team and associated project" do
    it "should add the user to the associated project" do
      project.users.map {|u| u.username}.should == []
      team.add_member(user, UserTeam.access_roles["Developer"], false)
      project.users.reload
      project.users.map {|u| u.username}.should == [user.username]
    end
  end

  describe "Delete member from team and associated project" do
    before do
      team.add_member(user, UserTeam.access_roles["Developer"], false)
    end

    it "should remove user from team and project" do
      project.users.map {|u| u.username}.should == [user.username]
      team.remove_member(user)
      project.users.reload
      project.users.map {|u| u.username}.should == []
    end
  end
end
