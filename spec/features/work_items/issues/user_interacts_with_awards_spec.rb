# frozen_string_literal: true

require 'spec_helper'

# Most award/reaction interactions were migrated to the MSW integration spec at
# spec/frontend/msw_integration/work_items/awards/award_emoji_spec.js. What stays
# here needs the real backend or the real emoji picker:
#   - Emoji picker selection: the picker renders its emoji list lazily via an
#     intersection observer that does not fire under jsdom, so selecting an emoji
#     from the picker cannot be exercised in the MSW spec.
#   - Comment/GFM parsing and the legacy invalid-emoji regression go through real
#     server-side code paths.
RSpec.describe 'User interacts with awards', :js, feature_category: :team_planning do
  include MobileHelpers

  let(:user) { create(:user) }

  describe 'User interacts with awards in an issue' do
    let(:issue) { create(:issue, project: project) }
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(project_issue_path(project, issue))
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

    it 'shows the list of award emoji categories',
      quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/5953' do
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

      it 'allows adding a new emoji' do
        within('.note') do
          click_button 'Add reaction', match: :first
          click_button '😆'

          expect(page).to have_button '😀 1'
          expect(page).to have_button '😆 1'
        end
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
        issue.award_emoji.build(user: user, name: 'heart_tip', namespace_id: issue.namespace_id).save!(validate: false)
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
