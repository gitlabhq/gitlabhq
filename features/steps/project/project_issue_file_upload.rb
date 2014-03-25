class ProjectIssueFileUpload < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  And 'project "Shop" have "Release 0.4" open issue' do
    project = Project.find_by(name: "Shop")
    create(:issue,
           title: "Release 0.4",
           project: project,
           author: project.users.first,
           description: "# Description header"
          )
  end

  And 'I click link "Edit"' do
    click_link "Edit"
  end

  And 'I click button "Save changes"' do
    click_button "Save changes"
  end

  And 'I click link "Delete"' do
    within(".issue-attachment") do
      find(".js-issue-attachment-delete").trigger("click")
      sleep 0.05
    end
  end

  Then 'I should see button "Choose File ..."' do
    page.should have_content "Choose File ..."
  end

  And 'issue "Release 0.4" has attachment "test_ss.ods"' do
    issue = Issue.find_by(title: "Release 0.4")
    issue.attachment = File.open("#{Rails.root}/features/support/test_ss.ods")
    issue.save!
  end

  And 'issue "Release 0.4" has attachment "insane-senior.jpg"' do
    issue = Issue.find_by(title: "Release 0.4")
    issue.attachment = File.open("#{Rails.root}/features/support/insane-senior.jpg")
    issue.save!
  end

  And 'I attach file "test_ss.ods"' do
    attach_file('issue_attachment', File.join(Rails.root, '/features/support/test_ss.ods'))
  end

  And 'I attach image "insane-senior.jpg"' do
    attach_file('issue_attachment', File.join(Rails.root, '/features/support/insane-senior.jpg'))
  end

  Then 'I should see link "test_ss.ods"' do
    page.should have_link "test_ss.ods"
  end

  Then 'I should not see link "test_ss.ods"' do
    page.should_not have_link "test_ss.ods"
  end

  Then 'I should see image "insane-senior.jpg"' do
    page.should have_xpath("//img[contains(@src, \"insane-senior.jpg\")]")
  end
end
