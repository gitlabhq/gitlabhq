# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Milestones sorting', :js, feature_category: :team_planning do
  include ListboxHelpers

  let(:user)    { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestones_for_sort_by) do
    {
      'Due later' => %w[b c a],
      'Name, ascending' => %w[a b c],
      'Name, descending' => %w[c b a],
      'Start later' => %w[a c b],
      'Start soon' => %w[b c a],
      'Due soon' => %w[a c b]
    }
  end

  let(:ordered_milestones) do
    ['Due soon', 'Due later', 'Start soon', 'Start later', 'Name, ascending', 'Name, descending']
  end

  before do
    create(:milestone, start_date: 7.days.from_now, due_date: 10.days.from_now, title: "a", project: project)
    create(:milestone, start_date: 6.days.from_now, due_date: 11.days.from_now, title: "c", project: project)
    create(:milestone, start_date: 5.days.from_now, due_date: 12.days.from_now, title: "b", project: project)
    sign_in(user)
  end

  it 'visit project milestones and sort by various orders' do
    visit project_milestones_path(project)

    expect(page).to have_button('Due soon')

    # assert default sorting order
    within '.milestones' do
      expect(page.all('[data-testid="milestone-link"]').map(&:text)).to eq(%w[a c b])
    end

    # assert milestones listed for given sort order
    selected_sort_order = 'Due soon'
    milestones_for_sort_by.each do |sort_by, expected_milestones|
      click_button selected_sort_order

      expect_listbox_items(ordered_milestones)

      select_listbox_item(sort_by)

      expect(page).to have_button(sort_by)

      within '.milestones' do
        expect(page.all('[data-testid="milestone-link"]').map(&:text)).to eq(expected_milestones)
      end

      selected_sort_order = sort_by
    end
  end
end
