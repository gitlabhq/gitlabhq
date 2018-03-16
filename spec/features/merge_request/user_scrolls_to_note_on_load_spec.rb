require 'rails_helper'

describe 'Merge request > User scrolls to note on load', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
  let(:fragment_id) { "#note_#{note.id}" }

  before do
    sign_in(user)
    page.current_window.resize_to(1000, 300)
    visit "#{project_merge_request_path(project, merge_request)}#{fragment_id}"
  end

  it 'scrolls down to fragment' do
    page_height = page.current_window.size[1]
    page_scroll_y = page.evaluate_script("window.scrollY")
    fragment_position_top = page.evaluate_script("Math.round($('#{fragment_id}').offset().top)")

    expect(find('.js-toggle-content').visible?).to eq true
    expect(find(fragment_id).visible?).to eq true
    expect(fragment_position_top).to be >= page_scroll_y
    expect(fragment_position_top).to be < (page_scroll_y + page_height)
  end
end
