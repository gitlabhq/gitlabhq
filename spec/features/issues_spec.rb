require 'spec_helper'

describe "Issues" do
  let(:project) { create(:project) }

  before do
    login_as :user
    user2 = create(:user)

    project.team << [[@user, user2], :developer]
  end

  describe "Edit issue" do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    before do
      visit project_issues_path(project)
      click_link "Edit"
    end

    it "should open new issue popup" do
      page.should have_content("Issue ##{issue.iid}")
    end

    describe "fill in" do
      before do
        fill_in "issue_title", with: "bug 345"
        fill_in "issue_description", with: "bug description"
      end

      it { expect { click_button "Save changes" }.to_not change {Issue.count} }

      it "should update issue fields" do
        click_button "Save changes"

        page.should have_content @user.name
        page.should have_content "bug 345"
        page.should have_content project.name
      end
    end

  end

  describe "Editing issue assignee" do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    it 'allows user to select unasigned', :js => true do
      visit edit_project_issue_path(project, issue)

      page.should have_content "Assign to #{@user.name}"

      page.first('#s2id_issue_assignee_id').click
      sleep 2 # wait for ajax stuff to complete
      page.first('.user-result').click

      click_button "Save changes"

      page.should have_content "Assignee: Select assignee"
      issue.reload.assignee.should be_nil
    end
  end

  describe "Filter issue" do
    before do
      ['foobar', 'barbaz', 'gitlab'].each do |title|
        create(:issue,
               author: @user,
               assignee: @user,
               project: project,
               title: title)
      end

      @issue = Issue.first # with title 'foobar'
      @issue.milestone = create(:milestone, project: project)
      @issue.assignee = nil
      @issue.save
    end

    let(:issue) { @issue }

    it "should allow filtering by issues with no specified milestone" do
      visit project_issues_path(project, milestone_id: '0')

      page.should_not have_content 'foobar'
      page.should have_content 'barbaz'
      page.should have_content 'gitlab'
    end

    it "should allow filtering by a specified milestone" do
      visit project_issues_path(project, milestone_id: issue.milestone.id)

      page.should have_content 'foobar'
      page.should_not have_content 'barbaz'
      page.should_not have_content 'gitlab'
    end

    it "should allow filtering by issues with no specified assignee" do
      visit project_issues_path(project, assignee_id: '0')

      page.should have_content 'foobar'
      page.should_not have_content 'barbaz'
      page.should_not have_content 'gitlab'
    end

    it "should allow filtering by a specified assignee" do
      visit project_issues_path(project, assignee_id: @user.id)

      page.should_not have_content 'foobar'
      page.should have_content 'barbaz'
      page.should have_content 'gitlab'
    end
  end

  describe 'filter issue' do
    titles = ['foo','bar','baz']
    titles.each_with_index do |title, index|
      let!(title.to_sym) { create(:issue, title: title, project: project, created_at: Time.now - (index * 60)) }
    end
    let(:newer_due_milestone) { create(:milestone, due_date: '2013-12-11') }
    let(:later_due_milestone) { create(:milestone, due_date: '2013-12-12') }

    it 'sorts by newest' do
      visit project_issues_path(project, sort: 'newest')

      first_issue.should include("foo")
      last_issue.should include("baz")
    end

    it 'sorts by oldest' do
      visit project_issues_path(project, sort: 'oldest')

      first_issue.should include("baz")
      last_issue.should include("foo")
    end

    it 'sorts by most recently updated' do
      baz.updated_at = Time.now + 100
      baz.save
      visit project_issues_path(project, sort: 'recently_updated')

      first_issue.should include("baz")
    end

    it 'sorts by least recently updated' do
      baz.updated_at = Time.now - 100
      baz.save
      visit project_issues_path(project, sort: 'last_updated')

      first_issue.should include("baz")
    end

    describe 'sorting by milestone' do
      before :each do
        foo.milestone = newer_due_milestone
        foo.save
        bar.milestone = later_due_milestone
        bar.save
      end

      it 'sorts by recently due milestone' do
        visit project_issues_path(project, sort: 'milestone_due_soon')

        first_issue.should include("foo")
      end

      it 'sorts by least recently due milestone' do
        visit project_issues_path(project, sort: 'milestone_due_later')

        first_issue.should include("bar")
      end
    end

    describe 'combine filter and sort' do
      let(:user2) { create(:user) }

      before :each do
        foo.assignee = user2
        foo.save
        bar.assignee = user2
        bar.save
      end

      it 'sorts with a filter applied' do
        visit project_issues_path(project, sort: 'oldest', assignee_id: user2.id)

        first_issue.should include("bar")
        last_issue.should include("foo")
        page.should_not have_content 'baz'
      end
    end
  end

  describe 'update assignee from issue#show' do
    let(:issue) { create(:issue, project: project, author: @user) }

    context 'by autorized user' do

      it 'with dropdown menu' do
        visit project_issue_path(project, issue)

        find('.edit-issue.inline-update #issue_assignee_id').set project.team.members.first.id
        click_button 'Update Issue'

        page.should have_content "Assignee:"
        page.has_select?('issue_assignee_id', :selected => project.team.members.first.name)
      end
    end

    context 'by unauthorized user' do

      let(:guest) { create(:user) }

      before :each do
        project.team << [[guest], :guest]
        issue.assignee = @user
        issue.save
      end

      it 'shows assignee text' do
        logout
        login_with guest

        visit project_issue_path(project, issue)
        page.should have_content issue.assignee.name
      end
    end
  end

  describe 'update milestone from issue#show' do
    let!(:issue) { create(:issue, project: project, author: @user) }
    let!(:milestone) { create(:milestone, project: project) }

    context 'by authorized user' do

      it 'with dropdown menu' do
        visit project_issue_path(project, issue)

        find('.edit-issue.inline-update').select(milestone.title, from: 'issue_milestone_id')
        click_button 'Update Issue'

        page.should have_content "Milestone"
        page.has_select?('issue_assignee_id', :selected => milestone.title)
      end
    end

    context 'by unauthorized user' do
      let(:guest) { create(:user) }

      before :each do
        project.team << [guest, :guest]
        issue.milestone = milestone
        issue.save
      end

      it 'shows milestone text' do
        logout
        login_with guest

        visit project_issue_path(project, issue)
        page.should have_content milestone.title
      end
    end

    describe 'removing assignee' do
      let(:user2) { create(:user) }

      before :each do
        issue.assignee = user2
        issue.save
      end

      it 'allows user to remove assignee', :js => true do
        visit project_issue_path(project, issue)
        page.should have_content "Assignee: #{user2.name}"

        page.first('#s2id_issue_assignee_id').click
        sleep 2 # wait for ajax stuff to complete
        page.first('.user-result').click

        page.should have_content "Assignee: Unassigned"
        sleep 2 # wait for ajax stuff to complete
        issue.reload.assignee.should be_nil
      end
    end
  end

  def first_issue
    all("ul.issues-list li").first.text
  end

  def last_issue
    all("ul.issues-list li").last.text
  end
end
