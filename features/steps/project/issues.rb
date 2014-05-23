class ProjectIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown

  Given 'I should see "Release 0.4" in issues' do
    page.should have_content "Release 0.4"
  end

  And 'I should not see "Release 0.3" in issues' do
    page.should_not have_content "Release 0.3"
  end

  And 'I should not see "Tweet control" in issues' do
    page.should_not have_content "Tweet control"
  end

  Given 'I click link "Closed"' do
    click_link "Closed"
  end

  Then 'I should see "Release 0.3" in issues' do
    page.should have_content "Release 0.3"
  end

  And 'I should not see "Release 0.4" in issues' do
    page.should_not have_content "Release 0.4"
  end

  Given 'I click link "All"' do
    click_link "All"
  end

  Given 'I click link "Release 0.4"' do
    click_link "Release 0.4"
  end

  Then 'I should see issue "Release 0.4"' do
    page.should have_content "Release 0.4"
  end

  Given 'I click link "New Issue"' do
    click_link "New Issue"
  end

  And 'I submit new issue "500 error on profile"' do
    fill_in "issue_title", with: "500 error on profile"
    click_button "Submit new issue"
  end

  Given 'I click link "500 error on profile"' do
    click_link "500 error on profile"
  end

  Then 'I should see issue "500 error on profile"' do
    issue = Issue.find_by(title: "500 error on profile")
    page.should have_content issue.title
    page.should have_content issue.author_name
    page.should have_content issue.project.name
  end

  Given 'I fill in issue search with "Re"' do
    fill_in 'issue_search', with: "Re"
  end

  Given 'I fill in issue search with "Bu"' do
    fill_in 'issue_search', with: "Bu"
  end

  And 'I fill in issue search with ".3"' do
    fill_in 'issue_search', with: ".3"
  end

  And 'I fill in issue search with "Something"' do
    fill_in 'issue_search', with: "Something"
  end

  And 'I fill in issue search with ""' do
    fill_in 'issue_search', with: ""
  end

  Given 'project "Shop" has milestone "v2.2"' do
    project = Project.find_by(name: "Shop")
    milestone = create(:milestone, title: "v2.2", project: project)

    3.times { create(:issue, project: project, milestone: milestone) }
  end

  And 'project "Shop" has milestone "v3.0"' do
    project = Project.find_by(name: "Shop")
    milestone = create(:milestone, title: "v3.0", project: project)

    3.times { create(:issue, project: project, milestone: milestone) }
  end

  When 'I select milestone "v3.0"' do
    select "v3.0", from: "milestone_id"
  end

  Then 'I should see selected milestone with title "v3.0"' do
    issues_milestone_selector = "#issue_milestone_id_chzn > a"
    page.find(issues_milestone_selector).should have_content("v3.0")
  end

  When 'I select first assignee from "Shop" project' do
    project = Project.find_by(name: "Shop")
    first_assignee = project.users.first
    select first_assignee.name, from: "assignee_id"
  end

  Then 'I should see first assignee from "Shop" as selected assignee' do
    issues_assignee_selector = "#issue_assignee_id_chzn > a"
    project = Project.find_by(name: "Shop")
    assignee_name = project.users.first.name
    page.find(issues_assignee_selector).should have_content(assignee_name)
  end

  And 'project "Shop" have "Release 0.4" open issue' do
    project = Project.find_by(name: "Shop")
    create(:issue,
           title: "Release 0.4",
           project: project,
           author: project.users.first,
           description: "# Description header"
          )
  end

  And 'project "Shop" have "Tweet control" open issue' do
    project = Project.find_by(name: "Shop")
    create(:issue,
           title: "Tweet control",
           project: project,
           author: project.users.first)
  end

  And 'project "Shop" have "Release 0.3" closed issue' do
    project = Project.find_by(name: "Shop")
    create(:closed_issue,
           title: "Release 0.3",
           project: project,
           author: project.users.first)
  end

  Given 'empty project "Empty Project"' do
    create :empty_project, name: 'Empty Project', namespace: @user.namespace
  end

  When 'I visit empty project page' do
    project = Project.find_by(name: 'Empty Project')
    visit project_path(project)
  end

  And 'I see empty project details with ssh clone info' do
    project = Project.find_by(name: 'Empty Project')
    page.all(:css, '.git-empty .clone').each do |element|
      element.text.should include(project.url_to_repo)
    end
  end

  When "I visit empty project's issues page" do
    project = Project.find_by(name: 'Empty Project')
    visit project_issues_path(project)
  end

  step 'I leave a comment with code block' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "```\nCommand [1]: /usr/local/bin/git , see [text](doc/text)\n```"
      click_button "Add Comment"
      sleep 0.05
    end
  end

  step 'The code block should be unchanged' do
    page.should have_content("```\nCommand [1]: /usr/local/bin/git , see [text](doc/text)\n```")
  end
end
