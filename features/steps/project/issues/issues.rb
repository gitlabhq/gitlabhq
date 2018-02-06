class Spinach::Features::ProjectIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown
  include SharedUser

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
    wait_for_requests
    expect(find('.js-issuable-subscribe-button')).to have_css 'button.is-checked'
  end

  step 'I should see that I am unsubscribed' do
    wait_for_requests
    expect(find('.js-issuable-subscribe-button')).to have_css 'button:not(.is-checked)'
  end

  step 'I click link "Closed"' do
    find('.issues-state-filters [data-state="closed"] span', text: 'Closed').click
  end

  step 'I click the subscription toggle' do
    find('.js-issuable-subscribe-button button').click
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

  step 'I click link "Release 0.4"' do
    click_link "Release 0.4"
  end

  step 'I should see issue "Release 0.4"' do
    expect(page).to have_content "Release 0.4"
  end

  step 'I should see issue "Tweet control"' do
    expect(page).to have_content "Tweet control"
  end

  step 'I click link "New issue"' do
    page.within '#content-body' do
      page.has_link?('New Issue') ? click_link('New Issue') : click_link('New issue')
    end
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

  step 'I submit new issue "500 error on profile"' do
    fill_in "issue_title", with: "500 error on profile"
    click_button "Submit issue"
  end

  step 'I submit new issue "500 error on profile" with label \'bug\'' do
    fill_in "issue_title", with: "500 error on profile"
    click_button "Label"
    click_link "bug"
    click_button "Submit issue"
  end

  step 'I click link "500 error on profile"' do
    click_link "500 error on profile"
  end

  step 'I should see label \'bug\' with issue' do
    page.within '.issuable-show-labels' do
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
    wait_for_requests
  end

  step 'project "Shop" have "Tweet control" open issue' do
    create(:issue,
           title: "Tweet control",
           project: project,
           author: project.users.first)
  end

  step 'project "Shop" have "Bugfix" open issue' do
    create(:issue,
           title: "Bugfix",
           project: project,
           author: project.users.first)
  end

  step 'project "Shop" have "Release 0.3" closed issue' do
    create(:closed_issue,
           title: "Release 0.3",
           project: project,
           author: project.users.first)
  end

  step 'issue "Release 0.4" have 2 upvotes and 1 downvote' do
    awardable = Issue.find_by(title: 'Release 0.4')
    create_list(:award_emoji, 2, awardable: awardable)
    create(:award_emoji, :downvote, awardable: awardable)
  end

  step 'issue "Tweet control" have 1 upvote and 2 downvotes' do
    awardable = Issue.find_by(title: 'Tweet control')
    create(:award_emoji, :upvote, awardable: awardable)
    create_list(:award_emoji, 2, awardable: awardable, name: 'thumbsdown')
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

  step 'The list should be sorted by "Popularity"' do
    page.within '.issues-list' do
      page.within 'li.issue:nth-child(1)' do
        expect(page).to have_content 'Release 0.4'
        expect(page).to have_content '2 1'
      end

      page.within 'li.issue:nth-child(2)' do
        expect(page).to have_content 'Tweet control'
        expect(page).to have_content '1 2'
      end

      page.within 'li.issue:nth-child(3)' do
        expect(page).to have_content 'Bugfix'
        expect(page).not_to have_content '0 0'
      end
    end
  end

  step 'empty project "Empty Project"' do
    create :project_empty_repo, name: 'Empty Project', namespace: @user.namespace
  end

  When 'I visit empty project page' do
    project = Project.find_by(name: 'Empty Project')
    visit project_path(project)
  end

  step 'I see empty project details with ssh clone info' do
    project = Project.find_by(name: 'Empty Project')
    page.all(:css, '.git-empty .clone').each do |element|
      expect(element.text).to include(project.url_to_repo)
    end
  end

  When "I visit project \"Community\" issues page" do
    project = Project.find_by(name: 'Community')
    visit project_issues_path(project)
  end

  When "I visit empty project's issues page" do
    project = Project.find_by(name: 'Empty Project')
    visit project_issues_path(project)
  end

  step 'I leave a comment with code block' do
    page.within(".js-main-target-form") do
      fill_in "note[note]", with: "```\nCommand [1]: /usr/local/bin/git , see [text](doc/text)\n```"
      click_button "Comment"
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
    fill_in 'issuable_search', with: text
  end
end
