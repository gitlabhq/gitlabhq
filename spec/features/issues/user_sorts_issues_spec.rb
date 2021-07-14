# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User sorts issues" do
  include SortingHelper
  include IssueHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project_empty_repo, :public, group: group) }
  let_it_be(:issue1, reload: true) { create(:issue, title: 'foo', created_at: Time.now, project: project) }
  let_it_be(:issue2, reload: true) { create(:issue, title: 'bar', created_at: Time.now - 60, project: project) }
  let_it_be(:issue3, reload: true) { create(:issue, title: 'baz', created_at: Time.now - 120, project: project) }
  let_it_be(:newer_due_milestone) { create(:milestone, project: project, due_date: '2013-12-11') }
  let_it_be(:later_due_milestone) { create(:milestone, project: project, due_date: '2013-12-12') }

  before do
    create_list(:award_emoji, 2, :upvote, awardable: issue1)
    create_list(:award_emoji, 2, :downvote, awardable: issue2)
    create(:award_emoji, :downvote, awardable: issue1)
    create(:award_emoji, :upvote, awardable: issue2)

    sign_in(user)
  end

  it 'keeps the sort option' do
    visit(project_issues_path(project))

    find('.filter-dropdown-container .dropdown').click

    page.within('ul.dropdown-menu.dropdown-menu-right li') do
      click_link('Milestone')
    end

    visit(issues_dashboard_path(assignee_username: user.username))

    expect(find('.issues-filters a.is-active')).to have_content('Milestone')

    visit(project_issues_path(project))

    expect(find('.issues-filters a.is-active')).to have_content('Milestone')

    visit(issues_group_path(group))

    expect(find('.issues-filters a.is-active')).to have_content('Milestone')
  end

  it 'sorts by popularity', :js do
    visit(project_issues_path(project))

    click_button 'Created date'
    click_on 'Popularity'

    page.within(".issues-list") do
      page.within("li.issue:nth-child(1)") do
        expect(page).to have_content(issue1.title)
      end

      page.within("li.issue:nth-child(2)") do
        expect(page).to have_content(issue2.title)
      end

      page.within("li.issue:nth-child(3)") do
        expect(page).to have_content(issue3.title)
      end
    end
  end

  it 'sorts by newest', :js do
    visit project_issues_path(project, sort: sort_value_created_date)

    expect(first_issue).to include('foo')
    expect(last_issue).to include('baz')
  end

  it 'sorts by most recently updated', :js do
    issue3.updated_at = Time.now + 100
    issue3.save!
    visit project_issues_path(project, sort: sort_value_recently_updated)

    expect(first_issue).to include('baz')
  end

  describe 'sorting by due date', :js do
    before do
      issue1.update!(due_date: 1.day.from_now)
      issue2.update!(due_date: 6.days.from_now)
    end

    it 'sorts by due date' do
      visit project_issues_path(project, sort: sort_value_due_date)

      expect(first_issue).to include('foo')
    end

    it 'sorts by due date by excluding nil due dates' do
      issue2.update!(due_date: nil)

      visit project_issues_path(project, sort: sort_value_due_date)

      expect(first_issue).to include('foo')
    end

    context 'with a filter on labels' do
      let(:label) { create(:label, project: project) }

      before do
        create(:label_link, label: label, target: issue1)
      end

      it 'sorts by least recently due date by excluding nil due dates' do
        issue2.update!(due_date: nil)

        visit project_issues_path(project, label_names: [label.name], sort: sort_value_due_date_later)

        expect(first_issue).to include('foo')
      end
    end
  end

  describe 'filtering by due date', :js do
    before do
      issue1.update!(due_date: 1.day.from_now)
      issue2.update!(due_date: 6.days.from_now)
    end

    it 'filters by none' do
      visit project_issues_path(project, due_date: Issue::NoDueDate.name)

      page.within '.issues-list' do
        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end
    end

    it 'filters by any' do
      visit project_issues_path(project, due_date: Issue::AnyDueDate.name)

      page.within '.issues-list' do
        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).to have_content('baz')
      end
    end

    it 'filters by due this week' do
      issue1.update!(due_date: Date.today.beginning_of_week + 2.days)
      issue2.update!(due_date: Date.today.end_of_week)
      issue3.update!(due_date: Date.today - 8.days)

      visit project_issues_path(project, due_date: Issue::DueThisWeek.name)

      page.within '.issues-list' do
        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).not_to have_content('baz')
      end
    end

    it 'filters by due this month' do
      issue1.update!(due_date: Date.today.beginning_of_month + 2.days)
      issue2.update!(due_date: Date.today.end_of_month)
      issue3.update!(due_date: Date.today - 50.days)

      visit project_issues_path(project, due_date: Issue::DueThisMonth.name)

      page.within '.issues-list' do
        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).not_to have_content('baz')
      end
    end

    it 'filters by overdue' do
      issue1.update!(due_date: Date.today + 2.days)
      issue2.update!(due_date: Date.today + 20.days)
      issue3.update!(due_date: Date.yesterday)

      visit project_issues_path(project, due_date: Issue::Overdue.name)

      page.within '.issues-list' do
        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end
    end

    it 'filters by due next month and previous two weeks' do
      issue1.update!(due_date: Date.today - 4.weeks)
      issue2.update!(due_date: (Date.today + 2.months).beginning_of_month)
      issue3.update!(due_date: Date.yesterday)

      visit project_issues_path(project, due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name)

      page.within '.issues-list' do
        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end
    end
  end

  describe 'sorting by milestone', :js do
    before do
      issue1.milestone = newer_due_milestone
      issue1.save!
      issue2.milestone = later_due_milestone
      issue2.save!
    end

    it 'sorts by milestone' do
      visit project_issues_path(project, sort: sort_value_milestone)

      expect(first_issue).to include('foo')
      expect(last_issue).to include('baz')
    end
  end

  describe 'combine filter and sort', :js do
    let(:user2) { create(:user) }

    before do
      issue1.assignees << user2
      issue1.save!
      issue2.assignees << user2
      issue2.save!
    end

    it 'sorts with a filter applied' do
      visit project_issues_path(project, sort: sort_value_created_date, assignee_id: user2.id)

      expect(first_issue).to include('foo')
      expect(last_issue).to include('bar')
      expect(page).not_to have_content('baz')
    end
  end
end
