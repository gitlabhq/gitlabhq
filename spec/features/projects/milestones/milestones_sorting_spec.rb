require 'spec_helper'

feature 'Milestones sorting', :js do
  include SortingHelper
  let(:user)    { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }

  before do
    # Milestones
    create(:milestone,
      due_date: 10.days.from_now,
      created_at:  2.hours.ago,
      title: "aaa", project: project)
    create(:milestone,
      due_date: 11.days.from_now,
      created_at:  1.hour.ago,
      title: "bbb", project: project)
    sign_in(user)
  end

  scenario 'visit project milestones and sort by due_date_asc' do
    visit project_milestones_path(project)

    expect(page).to have_button('Due soon')

    # assert default sorting
    within '.milestones' do
      expect(page.all('ul.content-list > li').first.text).to include('aaa')
      expect(page.all('ul.content-list > li').last.text).to include('bbb')
    end

    click_button 'Due soon'

    sort_options = find('ul.dropdown-menu-sort li').all('a').collect(&:text)

    expect(sort_options[0]).to eq('Due soon')
    expect(sort_options[1]).to eq('Due later')
    expect(sort_options[2]).to eq('Start soon')
    expect(sort_options[3]).to eq('Start later')
    expect(sort_options[4]).to eq('Name, ascending')
    expect(sort_options[5]).to eq('Name, descending')

    click_link 'Due later'

    expect(page).to have_button('Due later')

    within '.milestones' do
      expect(page.all('ul.content-list > li').first.text).to include('bbb')
      expect(page.all('ul.content-list > li').last.text).to include('aaa')
    end
  end
end
