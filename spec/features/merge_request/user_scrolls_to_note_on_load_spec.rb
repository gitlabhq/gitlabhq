require 'rails_helper'

describe 'Merge request > User scrolls to note on load', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
  let(:resolved_note) { create(:diff_note_on_merge_request, :resolved, noteable: merge_request, project: project) }
  let(:fragment_id) { "#note_#{note.id}" }
  let(:collapsed_fragment_id) { "#note_#{resolved_note.id}" }

  before do
    sign_in(user)
    page.current_window.resize_to(1000, 300)
  end

  it 'scrolls note into view' do
    visit "#{project_merge_request_path(project, merge_request)}#{fragment_id}"

    page_height = page.current_window.size[1]
    page_scroll_y = page.evaluate_script("window.scrollY")
    fragment_position_top = page.evaluate_script("Math.round($('#{fragment_id}').offset().top)")

    expect(find('.js-toggle-content').visible?).to eq true
    expect(find(fragment_id).visible?).to eq true
    expect(fragment_position_top).to be >= page_scroll_y
    expect(fragment_position_top).to be < (page_scroll_y + page_height)
  end

  it 'renders un-collapsed notes with diff' do
    page.current_window.resize_to(1000, 1000)

    visit "#{project_merge_request_path(project, merge_request)}#{fragment_id}"

    page.execute_script "window.scrollTo(0,0)"

    note_element = find(fragment_id)
    note_container = note_element.ancestor('.js-toggle-container')

    expect(note_element.visible?).to eq true

    page.within note_container do
      expect(page).not_to have_selector('.js-error-lazy-load-diff')
    end
  end

  it 'expands collapsed notes' do
    visit "#{project_merge_request_path(project, merge_request)}#{collapsed_fragment_id}"
    note_element = find(collapsed_fragment_id)
    note_container = note_element.ancestor('.js-toggle-container')

    expect(note_element.visible?).to eq true
    expect(note_container.find('.line_content.noteable_line.old', match: :first).visible?).to eq true
  end
end
