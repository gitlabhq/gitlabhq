class Groups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser
  include Select2Helper

  Then 'I should see group "Owned" projects list' do
    Group.find_by(name: "Owned").projects.each do |project|
      page.should have_link project.name
    end
  end

  And 'I should see projects activity feed' do
    page.should have_content 'closed issue'
  end

  Then 'I should see issues from group "Owned" assigned to me' do
    assigned_to_me(:issues).each do |issue|
      page.should have_content issue.title
    end
  end

  Then 'I should see merge requests from group "Owned" assigned to me' do
    assigned_to_me(:merge_requests).each do |issue|
      page.should have_content issue.title[0..80]
    end
  end

  And 'I select user "Mary Jane" from list with role "Reporter"' do
    user = User.find_by(name: "Mary Jane") || create(:user, name: "Mary Jane")
    click_link 'Add members'
    within ".users-group-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Reporter", from: "group_access"
    end
    click_button "Add users into group"
  end

  Then 'I should see user "John Doe" in team list' do
    projects_with_access = find(".panel .well-list")
    projects_with_access.should have_content("John Doe")
  end

  Then 'I should not see user "John Doe" in team list' do
    projects_with_access = find(".panel .well-list")
    projects_with_access.should_not have_content("John Doe")
  end

  Then 'I should see user "Mary Jane" in team list' do
    projects_with_access = find(".panel .well-list")
    projects_with_access.should have_content("Mary Jane")
  end

  Then 'I should not see user "Mary Jane" in team list' do
    projects_with_access = find(".panel .well-list")
    projects_with_access.should_not have_content("Mary Jane")
  end

  Given 'project from group "Owned" has issues assigned to me' do
    create :issue,
      project: project,
      assignee: current_user,
      author: current_user
  end

  Given 'project from group "Owned" has merge requests assigned to me' do
    create :merge_request,
      source_project: project,
      target_project: project,
      assignee: current_user,
      author: current_user
  end

  When 'I click new group link' do
    click_link "New group"
  end

  And 'submit form with new group "Samurai" info' do
    fill_in 'group_name', with: 'Samurai'
    fill_in 'group_description', with: 'Tokugawa Shogunate'
    click_button "Create group"
  end

  Then 'I should be redirected to group "Samurai" page' do
    current_path.should == group_path(Group.last)
  end

  Then 'I should see newly created group "Samurai"' do
    page.should have_content "Samurai"
    page.should have_content "Tokugawa Shogunate"
    page.should have_content "Currently you are only seeing events from the"
  end

  And 'I change group "Owned" name to "new-name"' do
    fill_in 'group_name', with: 'new-name'
    click_button "Save group"
  end

  Then 'I should see new group "Owned" name' do
    within ".navbar-gitlab" do
      page.should have_content "group: new-name"
    end
  end

  step 'I change group "Owned" avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save group"
    Group.find_by(name: "Owned").reload
  end

  step 'I should see new group "Owned" avatar' do
    Group.find_by(name: "Owned").avatar.should be_instance_of AttachmentUploader
    Group.find_by(name: "Owned").avatar.url.should == "/uploads/group/avatar/#{ Group.find_by(name:"Owned").id }/gitlab_logo.png"
  end

  step 'I should see the "Remove avatar" button' do
    page.should have_link("Remove avatar")
  end

  step 'I have group "Owned" avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save group"
    Group.find_by(name: "Owned").reload
  end

  step 'I remove group "Owned" avatar' do
    click_link "Remove avatar"
    Group.find_by(name: "Owned").reload
  end

  step 'I should not see group "Owned" avatar' do
    Group.find_by(name: "Owned").avatar?.should be_false
  end

  step 'I should not see the "Remove avatar" button' do
    page.should_not have_link("Remove avatar")
  end

  step 'I click on the "Remove User From Group" button for "John Doe"' do
    find(:css, 'li', text: "John Doe").find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I click on the "Remove User From Group" button for "Mary Jane"' do
    find(:css, 'li', text: "Mary Jane").find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "John Doe"' do
    find(:css, 'li', text: "John Doe").should_not have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "Mary Jane"' do
    find(:css, 'li', text: "Mary Jane").should_not have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I search for \'Mary\' member' do
    within '.member-search-form' do
      fill_in 'search', with: 'Mary'
      click_button 'Search'
    end
  end

  step 'I click on group milestones' do
    click_link 'Milestones'
  end

  step 'I should see group milestones index page has no milestones' do
    page.should have_content('No milestones to show')
  end

  step 'Group has projects with milestones' do
    group_milestone
  end

  step 'I should see group milestones index page with milestones' do
    page.should have_content('Version 7.2')
    page.should have_content('GL-113')
    page.should have_link('2 Issues', href: group_milestone_path("owned", "version-7-2", title: "Version 7.2"))
    page.should have_link('3 Merge Requests', href: group_milestone_path("owned", "gl-113", title: "GL-113"))
  end

  step 'I click on one group milestone' do
    click_link 'GL-113'
  end

  step 'I should see group milestone with descriptions and expiry date' do
    page.should have_content('Lorem Ipsum is simply dummy text of the printing and typesetting industry')
    page.should have_content('expires at Aug 20, 2014')
  end

  step 'I should see group milestone with all issues and MRs assigned to that milestone' do
    page.should have_content('Milestone GL-113')
    page.should have_content('Progress: 0 closed – 4 open')
    page.should have_link(@issue1.title, href: project_issue_path(@project1, @issue1))
    page.should have_link(@mr3.title, href: project_merge_request_path(@project3, @mr3))
  end

  protected

  def assigned_to_me key
    project.send(key).where(assignee_id: current_user.id)
  end

  def project
    Group.find_by(name: "Owned").projects.first
  end

  def group_milestone
    group = Group.find_by(name: "Owned")

    @project1 = create :project,
                 group: group
    project2 = create :project,
                 path: 'gitlab-ci',
                 group: group
    @project3 = create :project,
                 path: 'cookbook-gitlab',
                 group: group
    milestone1_project1 = create :milestone,
                            title: "Version 7.2",
                            project: @project1
    milestone1_project2 = create :milestone,
                            title: "Version 7.2",
                            project: project2
    milestone1_project3 = create :milestone,
                            title: "Version 7.2",
                            project: @project3
    milestone2_project1 = create :milestone,
                            title: "GL-113",
                            project: @project1
    milestone2_project2 = create :milestone,
                            title: "GL-113",
                            project: project2
    milestone2_project3 = create :milestone,
                            title: "GL-113",
                            project: @project3,
                            due_date: '2014-08-20',
                            description: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry'
    @issue1 = create :issue,
               project: @project1,
               assignee: current_user,
               author: current_user,
               milestone: milestone2_project1
    issue2 = create :issue,
               project: project2,
               assignee: current_user,
               author: current_user,
               milestone: milestone1_project2
    issue3 = create :issue,
               project: @project3,
               assignee: current_user,
               author: current_user,
               milestone: milestone1_project1
    mr1 = create :merge_request,
            source_project: @project1,
            target_project: @project1,
            assignee: current_user,
            author: current_user,
            milestone: milestone2_project1
    mr2 = create :merge_request,
            source_project: project2,
            target_project: project2,
            assignee: current_user,
            author: current_user,
            milestone: milestone2_project2
    @mr3 = create :merge_request,
            source_project: @project3,
            target_project: @project3,
            assignee: current_user,
            author: current_user,
            milestone: milestone2_project3
  end
end
