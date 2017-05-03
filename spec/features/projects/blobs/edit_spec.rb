require 'spec_helper'

feature 'Editing file blob', feature: true, js: true do
  include WaitForAjax

  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }
  given(:project) { merge_request.target_project }

  background do
    login_as(user)
    project.team << [user, role]
  end

  def edit_and_commit
    wait_for_ajax
    first('.file-actions').click_link 'Edit'
    execute_script('ace.edit("editor").setValue("class NextFeature\nend\n")')
    click_button 'Commit Changes'
  end

  context 'from MR diff' do
    before do
      visit diffs_namespace_project_merge_request_path(project.namespace, project, merge_request)
      edit_and_commit
    end

    scenario 'returns me to the mr' do
      expect(page).to have_content(merge_request.title)
    end
  end

  context 'from blob file path' do
    before do
      visit namespace_project_blob_path(project.namespace, project, '/feature/files/ruby/feature.rb')
      edit_and_commit
    end

    scenario 'updates content' do
      expect(page).to have_content 'successfully committed'
      expect(page).to have_content 'NextFeature'
    end
  end
end
