require 'spec_helper'

describe 'Variables' do
  before do
    login_as :user
    @project = FactoryGirl.create :project
    stub_js_gitlab_calls
    visit project_triggers_path(@project)
  end

  context 'create a trigger' do
    before do
      click_on 'Add Trigger'
      @project.triggers.count.should == 1
    end

    it 'contains trigger token' do
      page.should have_content(@project.triggers.first.token)
    end

    it 'revokes the trigger' do
      click_on 'Revoke'
      @project.triggers.count.should == 0
    end
  end
end
