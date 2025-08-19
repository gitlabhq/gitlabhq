# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group member autocomplete', :js, feature_category: :groups_and_projects do
  include Features::AutocompleteHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:noteable) { create(:milestone, group: group) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:private_group_member) { create(:user, username: 'private-a') }

  before_all do
    group.add_developer(user)
    private_group.add_developer(private_group_member)
    create(:group_group_link, shared_group: group, shared_with_group: private_group)
  end

  before do
    sign_in(user)
  end

  describe 'when editing description of a group milestone' do
    it 'suggests member of private group as well' do
      visit edit_group_milestone_path(group, noteable)

      fill_in 'Description', with: '@'

      expect(find_autocomplete_menu).to have_text(private_group_member.username)
      expect(find_autocomplete_menu).to have_text(user.username)
    end
  end
end
