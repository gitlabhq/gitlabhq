require 'spec_helper'

feature 'Milestones sorting', :js do
  let(:group) { create(:group) }
  let!(:project) { create(:project_empty_repo, group: group) }
  let!(:other_project) { create(:project_empty_repo, group: group) }
  let!(:project_milestone1) { create(:milestone, project: project, title: 'v1.0', due_date: 10.days.from_now) }
  let!(:other_project_milestone1) { create(:milestone, project: other_project, title: 'v1.0', due_date: 10.days.from_now) }
  let!(:project_milestone2) { create(:milestone, project: project, title: 'v2.0', due_date: 5.days.from_now) }
  let!(:other_project_milestone2) { create(:milestone, project: other_project, title: 'v2.0', due_date: 5.days.from_now) }
  let!(:group_milestone) { create(:milestone, group: group, title: 'v3.0', due_date: 7.days.from_now) }
  let(:user) { create(:group_member, :master, user: create(:user), group: group ).user }

  before do
    sign_in(user)
  end

  scenario 'visit group milestones and sort by due_date_asc' do
    visit group_milestones_path(group)

    expect(page).to have_button('Due soon')

    # assert default sorting
    within '.milestones' do
      expect(page.all('ul.content-list > li').first.text).to include('v2.0')
      expect(page.all('ul.content-list > li')[1].text).to include('v3.0')
      expect(page.all('ul.content-list > li').last.text).to include('v1.0')
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
      expect(page.all('ul.content-list > li').first.text).to include('v1.0')
      expect(page.all('ul.content-list > li')[1].text).to include('v3.0')
      expect(page.all('ul.content-list > li').last.text).to include('v2.0')
    end
  end
end
