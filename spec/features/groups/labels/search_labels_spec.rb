# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Search for labels', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:label1) { create(:group_label, title: 'Foo', description: 'Lorem ipsum', group: group) }
  let!(:label2) { create(:group_label, title: 'Bar', description: 'Fusce consequat', group: group) }

  before do
    group.add_maintainer(user)
    sign_in(user)

    visit group_labels_path(group)
  end

  it 'searches for label by title' do
    fill_in 'label-search', with: 'Bar'
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_content(label2.title)
    expect(page).to have_content(label2.description)
    expect(page).not_to have_content(label1.title)
    expect(page).not_to have_content(label1.description)
  end

  it 'searches for label by description' do
    fill_in 'label-search', with: 'Lorem'
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_content(label1.title)
    expect(page).to have_content(label1.description)
    expect(page).not_to have_content(label2.title)
    expect(page).not_to have_content(label2.description)
  end

  it 'shows nothing found message' do
    fill_in 'label-search', with: 'nonexistent'
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_content('No labels with such name or description')
    expect(page).not_to have_content(label1.title)
    expect(page).not_to have_content(label1.description)
    expect(page).not_to have_content(label2.title)
    expect(page).not_to have_content(label2.description)
  end

  it 'sorts by relevance when searching' do
    find('#label-search').fill_in(with: 'Bar')
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_button('Relevance')
  end
end
