# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GFM autocomplete', :js, feature_category: :team_planning do
  include Features::AutocompleteHelpers

  let_it_be(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let_it_be(:group) { create(:group, name: 'Ancestor', maintainers: user) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:issue) { create(:issue, project: project, assignees: [user], title: 'My special issue') }
  let_it_be(:label) { create(:label, project: project, title: 'special+') }
  let_it_be(:milestone) { create(:milestone, resource_parent: project, title: "project milestone") }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  shared_examples 'displays autocomplete menu for all entities' do
    it 'autocompletes all available entities' do
      fill_in 'Description', with: User.reference_prefix
      wait_for_requests
      expect(find_autocomplete_menu).to be_visible
      expect_autocomplete_entry(user.name)

      fill_in 'Description', with: Label.reference_prefix
      wait_for_requests
      expect(find_autocomplete_menu).to be_visible
      expect_autocomplete_entry(label.title)

      fill_in 'Description', with: Milestone.reference_prefix
      wait_for_requests
      expect(find_autocomplete_menu).to be_visible
      expect_autocomplete_entry(milestone.title)

      fill_in 'Description', with: Issue.reference_prefix
      wait_for_requests
      expect(find_autocomplete_menu).to be_visible
      expect_autocomplete_entry(issue.title)

      fill_in 'Description', with: MergeRequest.reference_prefix
      wait_for_requests
      expect(find_autocomplete_menu).to be_visible
      expect_autocomplete_entry(merge_request.title)
    end
  end

  describe 'new milestone page' do
    before do
      sign_in(user)
      visit new_project_milestone_path(project)

      wait_for_requests
    end

    it_behaves_like 'displays autocomplete menu for all entities'
  end

  describe 'update milestone page' do
    before do
      sign_in(user)
      visit edit_project_milestone_path(project, milestone)

      wait_for_requests
    end

    it_behaves_like 'displays autocomplete menu for all entities'
  end

  private

  def expect_autocomplete_entry(entry)
    page.within('.atwho-container') do
      expect(page).to have_content(entry)
    end
  end
end
