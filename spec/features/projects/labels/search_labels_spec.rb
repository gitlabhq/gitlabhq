# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Search for labels', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:label1) { create(:label, title: 'Foo', description: 'Lorem ipsum', project: project) }
  let!(:label2) { create(:label, title: 'Bar', description: 'Fusce consequat', project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_labels_path(project)
  end

  it 'searches for label by title' do
    fill_in 'label-search', with: 'Bar'
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_content(label2.title)
    expect(page).to have_content(label2.description)
    expect(page).not_to have_content(label1.title)
    expect(page).not_to have_content(label1.description)
  end

  it 'searches for label by title' do
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

  context 'priority labels' do
    let!(:label_priority) { create(:label_priority, label: label1, project: project) }

    it 'searches for priority label' do
      fill_in 'label-search', with: 'Foo'
      find('#label-search').native.send_keys(:enter)

      page.within('.prioritized-labels') do
        expect(page).to have_content(label1.title)
        expect(page).to have_content(label1.description)
      end

      page.within('.other-labels') do
        expect(page).to have_content('No other labels with such name or description')
      end
    end

    it 'searches for other label' do
      fill_in 'label-search', with: 'Bar'
      find('#label-search').native.send_keys(:enter)

      page.within('.prioritized-labels') do
        expect(page).to have_content('No prioritized labels with such name or description')
      end

      page.within('.other-labels') do
        expect(page).to have_content(label2.title)
        expect(page).to have_content(label2.description)
      end
    end
  end
end
