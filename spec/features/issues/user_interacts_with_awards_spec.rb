# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User interacts with awards', :js, feature_category: :team_planning do
  include MobileHelpers

  let(:user) { create(:user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  describe 'User interacts with awards in an issue' do
    let(:issue) { create(:issue, project: project) }
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(project_issue_path(project, issue))
    end

    it 'toggles the thumbsup award emoji' do
      page.within('.awards') do
        click_button '👍'
        find_button('👍').hover

        expect(page).to have_button '👍 1'

        click_button '👍'

        expect(page).not_to have_button '👍 1'
        expect(page).to have_button '👍'
        expect(page).to have_button '👎'

        click_button '👍'
        find_button('👍').hover

        expect(page).to have_button '👍 1'
      end
    end

    it 'toggles a custom award emoji' do
      click_button 'Add reaction'
      click_button '😀'
      find_button('😀').hover

      expect(page).to have_button '😀 1'
      expect(page).to have_text 'You reacted with :grinning:'

      click_button '😀 1'

      expect(page).not_to have_button '😀'
    end

    it 'shows the list of award emoji categories' do
      click_button 'Add reaction'
      fill_in('Search for an emoji', with: 'hand')

      expect(page).to have_button('✋')
    end

    it 'adds an award emoji by a comment' do
      fill_in('Add a reply', with: ':smile:')
      click_button 'Comment'

      expect(page).to have_emoji('smile')
    end

    context 'User interacts with awards on a note' do
      let!(:note) { create(:note, noteable: issue, project: issue.project) }
      let!(:award_emoji) { create(:award_emoji, awardable: note, name: 'grinning') }

      it 'shows the award on the note' do
        expect(page).to have_button('😀')
      end

      it 'allows adding a vote to an award' do
        click_button '😀'

        expect(page).to have_button '😀 2'
      end

      it 'allows adding a new emoji' do
        within('.note') do
          click_button 'Add reaction', match: :first
          click_button '😆'

          expect(page).to have_button '😀 1'
          expect(page).to have_button '😆 1'
        end
      end

      context 'when the project is archived' do
        let(:project) { create(:project, :archived) }

        it 'hides the buttons for adding new emoji' do
          page.within('.awards') do
            expect(page).not_to have_button 'Add reaction'
          end

          within_testid('note-wrapper') do
            expect(page).not_to have_button 'Add reaction'
          end
        end

        it 'does not allow toggling existing emoji' do
          click_button '😀'

          expect(page).not_to have_button '😀 2'
          expect(page).to have_button '😀 1'
        end
      end
    end
  end

  describe 'User interacts with awards on an issue' do
    let(:project)   { create(:project, :public) }
    let(:issue)     { create(:issue, project: project) }

    describe 'logged in' do
      context 'when the issue is locked' do
        before do
          create(:award_emoji, awardable: issue, name: '100')
          issue.update!(discussion_locked: true)

          sign_in(user)
          visit project_issue_path(project, issue)
        end

        it 'hides the add award button' do
          expect(page).not_to have_button 'Add reaction'
        end

        it 'does not allow toggling existing emoji' do
          click_button '💯'

          expect(page).not_to have_button '💯 2'
          expect(page).to have_button '💯 1'
        end
      end
    end

    describe 'logged out' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'does not see award menu button' do
        expect(page).not_to have_button 'Add reaction'
      end
    end
  end

  describe 'Awards Emoji' do
    let!(:project)   { create(:project, :public) }
    let(:issue)      { create(:issue, assignees: [user], project: project) }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe 'visiting an issue with a legacy award emoji that is not valid anymore' do
      before do
        # The `heart_tip` emoji is not valid anymore so we need to skip validation
        issue.award_emoji.build(user: user, name: 'heart_tip').save!(validate: false)
        visit project_issue_path(project, issue)
      end

      # Regression test: https://gitlab.com/gitlab-org/gitlab-foss/issues/29529
      it 'does not shows a 500 page' do
        expect(page).to have_text(issue.title)
      end
    end

    describe 'Click award emoji from issue#show' do
      let!(:note) { create(:note_on_issue, noteable: issue, project: issue.project, note: "Hello world") }

      before do
        visit project_issue_path(project, issue)
      end

      it 'toggles the smiley emoji on a note' do
        within('.note') do
          click_button 'Add reaction'
          click_button '😀'

          expect(page).to have_button '😀 1'

          click_button '😀'

          expect(page).not_to have_button '😀'
        end
      end
    end
  end
end
