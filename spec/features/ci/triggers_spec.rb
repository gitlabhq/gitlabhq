require 'spec_helper'

describe 'Triggers' do
  let(:user)    { create(:user) }

  before do
    login_as(user)
    @project = FactoryGirl.create :ci_project
    @project.gl_project.team << [user, :master]
    visit ci_project_triggers_path(@project)
  end

  context 'create a trigger' do
    before do
      click_on 'Add Trigger'
      expect(@project.triggers.count).to eq(1)
    end

    it 'contains trigger token' do
      expect(page).to have_content(@project.triggers.first.token)
    end

    it 'revokes the trigger' do
      click_on 'Revoke'
      expect(@project.triggers.count).to eq(0)
    end
  end
end
