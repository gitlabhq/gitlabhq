require 'spec_helper'

feature 'Diffs URL', js: true, feature: true do
  before do
    login_as :admin
    @merge_request = create(:merge_request)
    @project = @merge_request.source_project
  end

  context 'when visit with */* as accept header' do
    before(:each) do
      page.driver.add_header('Accept', '*/*')
    end

    it 'renders the notes' do
      create :note_on_merge_request, project: @project, noteable: @merge_request, note: 'Rebasing with master'

      visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)

      # Load notes and diff through AJAX
      expect(page).to have_css('.note-text', visible: false, text: 'Rebasing with master')
      expect(page).to have_css('.diffs.tab-pane.active')
    end
  end
end
