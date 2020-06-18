# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sort labels', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:label1) { create(:label, title: 'Foo', description: 'Lorem ipsum', project: project) }
  let!(:label2) { create(:label, title: 'Bar', description: 'Fusce consequat', project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_labels_path(project)
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

    sort_options = find('ul.dropdown-menu-sort li').all('a').collect(&:text)

    expect(sort_options[0]).to eq('Name')
    expect(sort_options[1]).to eq('Name, descending')
    expect(sort_options[2]).to eq('Last created')
    expect(sort_options[3]).to eq('Oldest created')
    expect(sort_options[4]).to eq('Last updated')
    expect(sort_options[5]).to eq('Oldest updated')

    click_link 'Name, descending'

    # assert default sorting
    within '.other-labels' do
      expect(page.all('.label-list-item').first.text).to include('Foo')
      expect(page.all('.label-list-item').last.text).to include('Bar')
    end
  end
end
