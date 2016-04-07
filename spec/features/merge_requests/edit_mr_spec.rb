require 'spec_helper'

feature 'Create New Merge Request', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

  before do
    project.team << [user, :master]

    login_as user

    visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'editing a MR', js: true do
    it 'should be able submit with quick_submit' do
      fill_in "merge_request_title", with: "Orphaned MR test"

      keypress = "var e = $.Event('keydown', { keyCode: 13, ctrlKey: true }); $('.merge-request-form').trigger(e);"
      page.driver.execute_script(keypress)
      sleep 2

      expect(find('h2.title')).to have_text('Orphaned MR test')
    end
  end
end