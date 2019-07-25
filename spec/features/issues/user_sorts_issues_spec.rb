# frozen_string_literal: true

require "spec_helper"

describe "User sorts issues" do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  set(:project) { create(:project_empty_repo, :public, group: group) }
  set(:issue1) { create(:issue, project: project) }
  set(:issue2) { create(:issue, project: project) }
  set(:issue3) { create(:issue, project: project) }

  before do
    create_list(:award_emoji, 2, :upvote, awardable: issue1)
    create_list(:award_emoji, 2, :downvote, awardable: issue2)
    create(:award_emoji, :downvote, awardable: issue1)
    create(:award_emoji, :upvote, awardable: issue2)

    sign_in(user)

    visit(project_issues_path(project))
  end

  it 'keeps the sort option' do
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

  it "sorts by popularity" do
    find('.filter-dropdown-container .dropdown').click

    page.within('ul.dropdown-menu.dropdown-menu-right li') do
      click_link("Popularity")
    end

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
end
