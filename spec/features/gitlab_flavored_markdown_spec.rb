require 'spec_helper'

describe "GitLab Flavored Markdown" do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:fred) do
    u = create(:user, name: "fred")
    project.team << [u, :master]
    u
  end

  before do
    Commit.any_instance.stub(title: "fix ##{issue.iid}\n\nask @#{fred.username} for details")
  end

  let(:commit) { project.repository.commit }

  before do
    login_as :user
    project.team << [@user, :developer]
  end

  describe "for commits" do
    it "should render title in commits#index" do
      visit project_commits_path(project, 'master', limit: 1)

      page.should have_link("##{issue.iid}")
    end

    it "should render title in commits#show" do
      visit project_commit_path(project, commit)

      page.should have_link("##{issue.iid}")
    end

    it "should render description in commits#show" do
      visit project_commit_path(project, commit)

      page.should have_link("@#{fred.username}")
    end

    it "should render title in repositories#branches" do
      visit project_branches_path(project)

      page.should have_link("##{issue.iid}")
    end
  end

  describe "for issues" do
    before do
      @other_issue = create(:issue,
                            author: @user,
                            assignee: @user,
                            project: project)
      @issue = create(:issue,
                      author: @user,
                      assignee: @user,
                      project: project,
                      title: "fix ##{@other_issue.iid}",
                      description: "ask @#{fred.username} for details")
    end

    it "should render subject in issues#index" do
      visit project_issues_path(project)

      page.should have_link("##{@other_issue.iid}")
    end

    it "should render subject in issues#show" do
      visit project_issue_path(project, @issue)

      page.should have_link("##{@other_issue.iid}")
    end

    it "should render details in issues#show" do
      visit project_issue_path(project, @issue)

      page.should have_link("@#{fred.username}")
    end
  end


  describe "for merge requests" do
    before do
      @merge_request = create(:merge_request, source_project: project, target_project: project, title: "fix ##{issue.iid}")
    end

    it "should render title in merge_requests#index" do
      visit project_merge_requests_path(project)

      page.should have_link("##{issue.iid}")
    end

    it "should render title in merge_requests#show" do
      visit project_merge_request_path(project, @merge_request)

      page.should have_link("##{issue.iid}")
    end
  end


  describe "for milestones" do
    before do
      @milestone = create(:milestone,
                          project: project,
                          title: "fix ##{issue.iid}",
                          description: "ask @#{fred.username} for details")
    end

    it "should render title in milestones#index" do
      visit project_milestones_path(project)

      page.should have_link("##{issue.iid}")
    end

    it "should render title in milestones#show" do
      visit project_milestone_path(project, @milestone)

      page.should have_link("##{issue.iid}")
    end

    it "should render description in milestones#show" do
      visit project_milestone_path(project, @milestone)

      page.should have_link("@#{fred.username}")
    end
  end
end
