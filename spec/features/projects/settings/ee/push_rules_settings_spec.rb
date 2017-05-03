require 'spec_helper'

describe 'Project settings > [EE] repository', feature: true do
  include Select2Helper
  
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

  describe 'mirror settings', :js do
    let(:user2) { create(:user) }

    before do
      project.team << [user2, :master]

      visit namespace_project_settings_repository_path(project.namespace, project)
    end

    it 'sets mirror user' do
      page.within('.edit_project') do
        select2(user2.id, from: '#project_mirror_user_id')

        click_button('Save changes')

        expect(find('.select2-chosen')).to have_content(user2.name)
      end
    end
  end
end
