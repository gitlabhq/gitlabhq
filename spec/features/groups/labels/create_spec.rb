# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a group label', :js, feature_category: :team_planning do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)

    visit new_group_label_path(group)
  end

  it 'renders the breadcrumbs', :aggregate_failures do
    within_testid('breadcrumb-links') do
      expect(page).to have_content("#{group.name} Labels New label")

      expect(page).to have_link(group.name, href: group_path(group))
      expect(page).to have_link('Labels', href: group_labels_path(group))
      expect(page).to have_link('New label', href: new_group_label_path(group))
    end
  end

  it 'creates a new label' do
    fill_in 'Title', with: 'test-label'
    click_button 'Create label'

    expect(page).to have_content 'test-label'
    expect(page).to have_current_path(group_labels_path(group), ignore_query: true)
  end

  it_behaves_like 'lock_on_merge when creating labels'
end
