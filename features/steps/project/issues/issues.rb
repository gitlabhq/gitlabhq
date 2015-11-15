class Spinach::Features::ProjectIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown

  step 'I should see "Release 0.4" in issues' do
    expect(page).to have_content "Release 0.4"
  end

  step 'I should not see "Release 0.3" in issues' do
    expect(page).not_to have_content "Release 0.3"
  end

  step 'I should not see "Tweet control" in issues' do
    expect(page).not_to have_content "Tweet control"
  end

  step 'I should see that I am subscribed' do
    expect(find('.subscribe-button span')).to have_content 'Unsubscribe'
  end

  step 'I should see that I am unsubscribed' do
    expect(find('.subscribe-button span')).to have_content 'Subscribe'
  end

  step 'I click link "Closed"' do
    click_link "Closed"
  end

  step 'I click button "Unsubscribe"' do
    click_on "Unsubscribe"
  end

  step 'I should see "Release 0.3" in issues' do
    expect(page).to have_content "Release 0.3"
  end

  step 'I should not see "Release 0.4" in issues' do
    expect(page).not_to have_content "Release 0.4"
  end

  step 'I click link "All"' do
    click_link "All"
  end

  step 'I click link "Release 0.4"' do
    click_link "Release 0.4"
  end

  step 'I should see issue "Release 0.4"' do
    expect(page).to have_content "Release 0.4"
  end

  step 'I click link "New Issue"' do
    click_link "New Issue"
  end

  step 'I click "author" dropdown' do
    first('.ajax-users-select').click
  end

  step 'I see current user as the first user' do
    expect(page).to have_selector('.user-result', visible: true, count: 4)
    users = page.all('.user-name')
    expect(users[0].text).to eq 'Any'
    expect(users[1].text).to eq 'Unassigned'
    expect(users[2].text).to eq current_user.name
  end

  step 'I submit new issue "500 error on profile"' do
    fill_in "issue_title", with: "500 error on profile"
    click_button "Submit new issue"
  end

  step 'I submit new issue "500 error on profile" with label \'bug\'' do
    fill_in "issue_title", with: "500 error on profile"
    select 'bug', from: "Labels"
    click_button "Submit new issue"
  end

  step 'I click link "500 error on profile"' do
    click_link "500 error on profile"
  end

  step 'I should see label \'bug\' with issue' do
    page.within '.issue-show-labels' do
      expect(page).to have_content 'bug'
    end
  end

  step 'I should see issue "500 error on profile"' do
    issue = Issue.find_by(title: "500 error on profile")
    expect(page).to have_content issue.title
    expect(page).to have_content issue.author_name
    expect(page).to have_content issue.project.name
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

  step 'project "Shop" have "Release 0.4" open issue' do

    create(:issue,
           title: "Release 0.4",
           project: project,
           author: project.users.first,
           description: "# Description header"
          )
  end

  step 'project "Shop" have "Tweet control" open issue' do
    create(:issue,
           title: "Tweet control",
           project: project,
           author: project.users.first)
  end

  step 'project "Shop" have "Release 0.3" closed issue' do
    create(:closed_issue,
           title: "Release 0.3",
           project: project,
           author: project.users.first)
  end

  step 'empty project "Empty Project"' do
    create :empty_project, name: 'Empty Project', namespace: @user.namespace
  end

  When 'I visit empty project page' do
    project = Project.find_by(name: 'Empty Project')
    visit namespace_project_path(project.namespace, project)
  end

  step 'I see empty project details with ssh clone info' do
    project = Project.find_by(name: 'Empty Project')
    page.all(:css, '.git-empty .clone').each do |element|
      expect(element.text).to include(project.url_to_repo)
    end
  end

  When "I visit project \"Community\" issues page" do
    project = Project.find_by(name: 'Community')
    visit namespace_project_issues_path(project.namespace, project)
  end

  When "I visit empty project's issues page" do
    project = Project.find_by(name: 'Empty Project')
    visit namespace_project_issues_path(project.namespace, project)
  end

  step 'I leave a comment with code block' do
    page.within(".js-main-target-form") do
      fill_in "note[note]", with: "```\nCommand [1]: /usr/local/bin/git , see [text](doc/text)\n```"
      click_button "Add Comment"
      sleep 0.05
    end
  end

  step 'I should see an error alert section within the comment form' do
    page.within(".js-main-target-form") do
      find(".error-alert")
    end
  end

  step 'The code block should be unchanged' do
    expect(page).to have_content("```\nCommand [1]: /usr/local/bin/git , see [text](doc/text)\n```")
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
    filter_issue 'Description for issue'
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

  step 'issue \'Release 0.4\' has label \'bug\'' do
    label = project.labels.create!(name: 'bug', color: '#990000')
    issue = Issue.find_by!(title: 'Release 0.4')
    issue.labels << label
  end

  step 'I click label \'bug\'' do
    page.within ".issues-list" do
      click_link 'bug'
    end
  end

  step 'I should not see labels field' do
    page.within '.issue-form' do
      expect(page).not_to have_content("Labels")
    end
  end

  step 'I should not see milestone field' do
    page.within '.issue-form' do
      expect(page).not_to have_content("Milestone")
    end
  end

  step 'I should not see assignee field' do
    page.within '.issue-form' do
      expect(page).not_to have_content("Assign to")
    end
  end

  def filter_issue(text)
    fill_in 'issue_search', with: text
  end
end
