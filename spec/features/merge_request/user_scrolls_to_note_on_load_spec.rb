# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User scrolls to note on load', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }
  let(:fragment_id) { "#note_#{note.id}" }

  before do
    sign_in(user)
    page.current_window.resize_to(1200, 800)
  end

  it 'scrolls note into view' do
    visit "#{project_merge_request_path(project, merge_request)}#{fragment_id}"

    expect(page).to have_selector(fragment_id.to_s)

    wait_for('note to be scrolled into view') do
      page.evaluate_script("document.querySelector('.js-static-panel-inner').scrollTop") > 0
    end

    panel_scroll_top, fragment_position_top = page.evaluate_script(<<~JS)
      [
        document.querySelector('.js-static-panel-inner').scrollTop,
        Math.round(
          document.querySelector('#{fragment_id}').getBoundingClientRect().top +
          document.querySelector('.js-static-panel-inner').scrollTop
        )
      ]
    JS

    expect(fragment_position_top).to be >= panel_scroll_top
  end

  it 'renders un-collapsed notes with diff' do
    page.current_window.resize_to(1000, 1000)

    visit "#{project_merge_request_path(project, merge_request)}#{fragment_id}"

    page.execute_script "document.querySelector('.js-static-panel-inner').scrollTo(0,0)"

    note_container = find(fragment_id).ancestor('.js-discussion-container')

    page.within note_container do
      expect(page).not_to have_selector('.js-error-lazy-load-diff')
    end
  end

  context 'resolved notes' do
    let(:collapsed_fragment_id) { "#note_#{resolved_note.id}" }

    context 'when diff note' do
      let(:resolved_note) { create(:diff_note_on_merge_request, :resolved, noteable: merge_request, project: project) }

      it 'expands collapsed notes' do
        visit "#{project_merge_request_path(project, merge_request)}#{collapsed_fragment_id}"

        expect(page).to have_selector(".diff-content #{collapsed_fragment_id}")
      end
    end

    context 'when non-diff note' do
      let(:non_diff_discussion) { create(:discussion_note_on_merge_request, :resolved, noteable: merge_request, project: project) }
      let(:resolved_note) { create(:discussion_note_on_merge_request, :resolved, noteable: merge_request, project: project, in_reply_to: non_diff_discussion) }

      it 'expands collapsed replies' do
        visit "#{project_merge_request_path(project, merge_request)}#{collapsed_fragment_id}"

        note_element = find(collapsed_fragment_id)

        expect(note_element.sibling('li:nth-child(2)')).to have_button s_('Notes|Collapse replies')
      end
    end
  end
end
