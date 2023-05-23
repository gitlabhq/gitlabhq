# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comment sort direction', feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:comment_1) { create(:note_on_issue, noteable: issue, project: project, note: 'written first') }
  let_it_be(:comment_2) { create(:note_on_issue, noteable: issue, project: project, note: 'written second') }

  context 'on issue page', :js do
    before do
      visit project_issue_path(project, issue)
    end

    it 'saves sort order' do
      # open dropdown, and select 'Newest first'
      page.within('.issuable-details') do
        click_button('Sort or filter')
        click_button('Newest first')
      end

      expect(first_comment).to have_content(comment_2.note)
      expect(last_comment).to have_content(comment_1.note)

      visit project_issue_path(project, issue)
      wait_for_requests

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
