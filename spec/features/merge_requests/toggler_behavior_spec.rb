require 'spec_helper'

feature 'toggler_behavior', js: true, feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
  let(:fragment_id) { "#note_#{note.id}" }

  before do
    login_as :admin
    project = merge_request.source_project
    visit "#{namespace_project_merge_request_path(project.namespace, project, merge_request)}#{fragment_id}"
    page.current_window.resize_to(1000, 300)
  end

  describe 'scroll position' do
    it 'should be scrolled down to fragment' do
      page_height = page.current_window.size[1]
      page_scroll_y = page.evaluate_script("window.scrollY")
      fragment_position_top = page.evaluate_script("$('#{fragment_id}').offset().top")
      expect(find('.js-toggle-content').visible?).to eq true
      expect(find(fragment_id).visible?).to eq true
      expect(fragment_position_top).to be >= page_scroll_y
      expect(fragment_position_top).to be < (page_scroll_y + page_height)
    end
  end
end
