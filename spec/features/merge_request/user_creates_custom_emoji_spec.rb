# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User creates custom emoji', :js, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, namespace: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, author: user) }

  context 'with user who has permissions' do
    before_all do
      group.add_owner(user)
    end

    before do
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'shows link to create custom emoji', :js do
      find_by_testid('add-reaction-button').click

      wait_for_requests

      click_link 'Create new emoji'

      wait_for_requests

      find_by_testid("custom-emoji-name-input").set 'flying_parrot'
      find_by_testid("custom-emoji-url-input").set 'https://example.com'

      click_button 'Save'

      wait_for_requests

      expect(page).to have_content(':flying_parrot:')
    end
  end

  context 'with user who does not have permissions' do
    before do
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'shows link to create custom emoji', :js do
      find_by_testid('add-reaction-button').click

      wait_for_requests

      expect(page).not_to have_link('Create new emoji')
    end
  end
end
