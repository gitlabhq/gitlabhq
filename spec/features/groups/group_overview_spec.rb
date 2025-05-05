# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group information', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) do
    create(:group_with_deletion_schedule, marked_for_deletion_on: Time.current, owners: user)
  end

  let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: group) }

  subject(:visit_page) { visit group_path(group) }

  before do
    sign_in(user)
  end

  context 'when group is pending deletion' do
    it 'shows pending deletion badge' do
      visit_page

      expect(page).to have_content 'Pending deletion'
    end

    it 'shows pending deletion badge on subgroups' do
      visit group_path(subgroup)

      expect(page).to have_content 'Pending deletion'
    end
  end
end
