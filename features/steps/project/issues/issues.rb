class Spinach::Features::ProjectIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown
  include SharedUser

  step 'I should not see "Release 0.3" in issues' do
    expect(page).not_to have_content "Release 0.3"
  end

  step 'I click link "Closed"' do
    find('.issues-state-filters [data-state="closed"] span', text: 'Closed').click
  end

  step 'I should see "Release 0.3" in issues' do
    expect(page).to have_content "Release 0.3"
  end

  step 'I should not see "Release 0.4" in issues' do
    expect(page).not_to have_content "Release 0.4"
  end

  step 'I click link "All"' do
    find('.issues-state-filters [data-state="all"] span', text: 'All').click
    # Waits for load
    expect(find('.issues-state-filters > .active')).to have_content 'All'
  end

  step 'I should see issue "Tweet control"' do
    expect(page).to have_content "Tweet control"
  end

  step 'I click "author" dropdown' do
    page.find('.js-author-search').click
    sleep 1
  end

  step 'I see current user as the first user' do
    expect(page).to have_selector('.dropdown-content', visible: true)
    users = page.all('.dropdown-menu-author .dropdown-content li a')
    expect(users[0].text).to eq 'Any Author'
    expect(users[1].text).to eq "#{current_user.name} #{current_user.to_reference}"
  end

  step 'I click link "500 error on profile"' do
    click_link "500 error on profile"
  end

  step 'I should see label \'bug\' with issue' do
    page.within '.issuable-show-labels' do
      expect(page).to have_content 'bug'
    end
  end

  step 'I fill in issue search with "Re"' do
    filter_issue "Re"
  end

  step 'I fill in issue search with "Bu"' do
    filter_issue "Bu"
  end

  step 'I fill in issue search with ".3"' do
    filter_issue ".3"
  end

  step 'I fill in issue search with "Something"' do
    filter_issue "Something"
  end

  step 'I fill in issue search with ""' do
    filter_issue ""
  end

  step 'project "Shop" has milestone "v2.2"' do
    milestone = create(:milestone, title: "v2.2", project: project)

    3.times { create(:issue, project: project, milestone: milestone) }
  end

  step 'project "Shop" has milestone "v3.0"' do
    milestone = create(:milestone, title: "v3.0", project: project)

    3.times { create(:issue, project: project, milestone: milestone) }
  end

  When 'I select milestone "v3.0"' do
    select "v3.0", from: "milestone_id"
  end

  step 'I should see selected milestone with title "v3.0"' do
    issues_milestone_selector = "#issue_milestone_id_chzn > a"
    expect(find(issues_milestone_selector)).to have_content("v3.0")
  end

  When 'I select first assignee from "Shop" project' do
    first_assignee = project.users.first
    select first_assignee.name, from: "assignee_id"
  end

  step 'I should see first assignee from "Shop" as selected assignee' do
    issues_assignee_selector = "#issue_assignee_id_chzn > a"

    assignee_name = project.users.first.name
    expect(find(issues_assignee_selector)).to have_content(assignee_name)
  end

  step 'The list should be sorted by "Least popular"' do
    page.within '.issues-list' do
      page.within 'li.issue:nth-child(1)' do
        expect(page).to have_content 'Tweet control'
        expect(page).to have_content '1 2'
      end

      page.within 'li.issue:nth-child(2)' do
        expect(page).to have_content 'Release 0.4'
        expect(page).to have_content '2 1'
      end

      page.within 'li.issue:nth-child(3)' do
        expect(page).to have_content 'Bugfix'
        expect(page).not_to have_content '0 0'
      end
    end
  end

  When 'I visit empty project page' do
    project = Project.find_by(name: 'Empty Project')
    visit project_path(project)
  end

  When "I visit project \"Community\" issues page" do
    project = Project.find_by(name: 'Community')
    visit project_issues_path(project)
  end

  step 'project \'Shop\' has issue \'Bugfix1\' with description: \'Description for issue1\'' do
    create(:issue, title: 'Bugfix1', description: 'Description for issue1', project: project)
  end

  step 'project \'Shop\' has issue \'Feature1\' with description: \'Feature submitted for issue1\'' do
    create(:issue, title: 'Feature1', description: 'Feature submitted for issue1', project: project)
  end

  step 'I fill in issue search with \'Description for issue1\'' do
    filter_issue 'Description for issue'
  end

  step 'I fill in issue search with \'issue1\'' do
    filter_issue 'issue1'
  end

  step 'I fill in issue search with \'Rock and roll\'' do
    filter_issue 'Rock and roll'
  end

  step 'I should see \'Bugfix1\' in issues' do
    expect(page).to have_content 'Bugfix1'
  end

  step 'I should see \'Feature1\' in issues' do
    expect(page).to have_content 'Feature1'
  end

  step 'I should not see \'Bugfix1\' in issues' do
    expect(page).not_to have_content 'Bugfix1'
  end

  def filter_issue(text)
    fill_in 'issuable_search', with: text
  end
end
