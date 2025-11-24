# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comment sort direction', feature_category: :team_planning do
  include ListboxHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:comment_1) { create(:note_on_issue, noteable: issue, project: project, note: 'written first') }
  let_it_be(:comment_2) { create(:note_on_issue, noteable: issue, project: project, note: 'written second') }

  let_it_be(:developer) { create(:user, developer_of: project) }

  before do
    sign_in(developer)
  end

  context 'on issue page', :js do
    before do
      visit project_issue_path(project, issue)
    end

    it 'saves sort order' do
      select_sort_order('Newest first')

      expect(first_comment).to have_content(comment_2.note)
      expect(last_comment).to have_content(comment_1.note)

      visit project_issue_path(project, issue)

      expect(first_comment).to have_content(comment_2.note)
      expect(last_comment).to have_content(comment_1.note)
    end

    context 'when creating new notes' do
      it 'adds new comments at the correct locations' do
        expect(last_comment).to have_content(comment_2.note)

        add_comment('A new note')
        expect(last_comment).to have_content('A new note')

        select_sort_order('Newest first')

        add_comment('Another new note')
        expect(first_comment).to have_content('Another new note')
      end

      context 'when notes are loaded newest first from the backend' do
        before do
          select_sort_order('Newest first')

          # Reload page so we load the discussions in the stored order
          visit project_issue_path(project, issue)
        end

        it 'adds new comments at the correct locations' do
          expect(first_comment).to have_content(comment_2.note)

          add_comment('A new note')
          expect(first_comment).to have_content('A new note')

          select_sort_order('Oldest first')

          add_comment('Another new note')
          expect(last_comment).to have_content('Another new note')
        end
      end
    end
  end

  def select_sort_order(order)
    find_by_testid('work-item-sort').click
    select_listbox_item(order)
  end

  def all_comments
    all('.timeline li.note.timeline-entry')
  end

  def first_comment
    all_comments.first
  end

  def last_comment
    all_comments.last
  end

  def add_comment(text)
    fill_in 'Add a reply', with: text
    click_button 'Comment'
  end
end
