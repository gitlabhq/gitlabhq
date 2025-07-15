# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comment sort direction', feature_category: :team_planning do
  include ListboxHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:comment_1) { create(:note_on_issue, noteable: issue, project: project, note: 'written first') }
  let_it_be(:comment_2) { create(:note_on_issue, noteable: issue, project: project, note: 'written second') }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'on issue page', :js do
    before do
      visit project_issue_path(project, issue)
    end

    it 'saves sort order' do
      # open dropdown, and select 'Newest first'
      click_button('Oldest first')
      select_listbox_item('Newest first')

      expect(first_comment).to have_content(comment_2.note)
      expect(last_comment).to have_content(comment_1.note)

      visit project_issue_path(project, issue)

      expect(first_comment).to have_content(comment_2.note)
      expect(last_comment).to have_content(comment_1.note)
    end
  end

  def all_comments
    all('.timeline > .note.timeline-entry')
  end

  def first_comment
    all_comments.first
  end

  def last_comment
    all_comments.last
  end
end
