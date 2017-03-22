require 'spec_helper'

describe 'Project settings > [EE] Push Rules', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  describe 'editing a push rule' do
    let(:commit_message) { 'Required part of every message' }
    let(:input_id) { 'push_rule_commit_message_regex' }

    before do
      visit namespace_project_settings_repository_path(project.namespace, project)

      fill_in input_id, with: commit_message
      click_button 'Save Push Rules'
    end

    it 'displays the new value in the form' do
      expect(find("##{input_id}").value).to eq commit_message
    end

    it 'saves the new value' do
      expect(project.push_rule.commit_message_regex).to eq commit_message
    end
  end
end
