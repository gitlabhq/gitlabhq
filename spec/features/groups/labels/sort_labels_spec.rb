# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sort labels', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:label1) { create(:group_label, title: 'Foo', description: 'Lorem ipsum', group: group) }
  let!(:label2) { create(:group_label, title: 'Bar', description: 'Fusce consequat', group: group) }

  before do
    group.add_maintainer(user)
    sign_in(user)

    visit group_labels_path(group)
  end

  it 'sorts by title by default' do
    expect(page).to have_button('Name')

    # assert default sorting
    within '.other-labels' do
      expect(page.all('.label-list-item').first.text).to include('Bar')
      expect(page.all('.label-list-item').last.text).to include('Foo')
    end
  end

  it 'sorts by date' do
    click_button 'Name'

    sort_options = find('ul[role="listbox"]').all('li').collect(&:text)

    expect(sort_options[0]).to eq('Name')
    expect(sort_options[1]).to eq('Name, descending')
    expect(sort_options[2]).to eq('Last created')
    expect(sort_options[3]).to eq('Oldest created')
    expect(sort_options[4]).to eq('Updated date')
    expect(sort_options[5]).to eq('Oldest updated')

    find('li', text: 'Name, descending').click

    # assert default sorting
    within '.other-labels' do
      expect(page.all('.label-list-item').first.text).to include('Foo')
      expect(page.all('.label-list-item').last.text).to include('Bar')
    end
  end
end
