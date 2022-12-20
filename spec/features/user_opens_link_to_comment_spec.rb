# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User opens link to comment', :js, feature_category: :team_planning do
  let(:project) { create(:project, :public) }
  let(:note) { create(:note_on_issue, project: project) }

  context 'authenticated user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'switches to all activity and does not show error message' do
      create(:user_preference, user: user, issue_notes_filter: UserPreference::NOTES_FILTERS[:only_activity])

      visit Gitlab::UrlBuilder.build(note)

      wait_for_requests

      expect(find('#discussion-preferences-dropdown')).to have_content(_('Sort or filter'))
      expect(page).not_to have_content('Something went wrong while fetching comments')

      # Auto-switching to show all notes shouldn't be persisted
      expect(user.reload.notes_filter_for(note.noteable)).to eq(UserPreference::NOTES_FILTERS[:only_activity])
    end
  end

  context 'anonymous user' do
    it 'does not show error message' do
      visit Gitlab::UrlBuilder.build(note)

      expect(page).not_to have_content('Something went wrong while fetching comments')
    end
  end
end
