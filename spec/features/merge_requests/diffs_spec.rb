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

  context 'when merge request has overflow' do
    it 'displays warning' do
      allow_any_instance_of(MergeRequestDiff).to receive(:overflow?).and_return(true)
      allow(Commit).to receive(:max_diff_options).and_return(max_files: 20, max_lines: 20)

      visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)

      page.within('.alert') do
        expect(page).to have_text("Too many changes to show. Plain diff Email patch To preserve
          performance only 3 of 3+ files are displayed.")
      end
    end
  end
end
