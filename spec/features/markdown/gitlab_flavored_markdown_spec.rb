# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "GitLab Flavored Markdown", feature_category: :markdown do
  # Ensure support bot user is created so creation doesn't count towards query limit
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
  let_it_be(:support_bot) { Users::Internal.support_bot }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:fred) do
    create(:user, name: 'fred') do |user|
      project.add_maintainer(user)
    end
  end

  before do
    sign_in(user)
    project.add_developer(user)
  end

  describe "for commits" do
    let(:project) { create(:project, :repository) }
    let(:commit) { project.commit }

    before do
      project.repository.commit_files(
        user,
        branch_name: 'master',
        message: "fix #{issue.to_reference}\n\nask #{fred.to_reference} for details",
        actions: [{ action: :create, file_path: 'a/new.file', content: 'This is a file' }]
      )
    end

    it "renders title in commits#index" do
      visit project_commits_path(project, 'master', limit: 1)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders title in commits#show" do
      visit project_commit_path(project, commit)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders description in commits#show" do
      visit project_commit_path(project, commit)

      expect(page).to have_link(fred.to_reference)
    end

    it "renders title in repositories#branches" do
      visit project_branches_path(project)

      expect(page).to have_link(issue.to_reference)
    end
  end

  describe "for issues", :js do
    before do
      @other_issue = create(
        :issue,
        author: user,
        assignees: [user],
        project: project
      )

      @issue = create(
        :issue,
        author: user,
        assignees: [user],
        project: project,
        title: "fix #{@other_issue.to_reference}",
        description: "ask #{fred.to_reference} for details"
      )

      @note = create(:note_on_issue, noteable: @issue, project: @issue.project, note: "Hello world")
    end

    it "renders subject in issues#index" do
      visit project_issues_path(project)

      expect(page).to have_link(@other_issue.to_reference)
    end

    it "renders subject in issues#show" do
      visit project_issue_path(project, @issue)

      expect(page).to have_link(@other_issue.to_reference)
    end

    it "renders details in issues#show" do
      visit project_issue_path(project, @issue)

      expect(page).to have_link(fred.to_reference)
    end
  end

  describe "for merge requests" do
    let(:project) { create(:project, :repository) }

    before do
      @merge_request = create(:merge_request, source_project: project, target_project: project, title: "fix #{issue.to_reference}")
    end

    it "renders title in merge_requests#index", :js do
      visit project_merge_requests_path(project)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders title in merge_requests#show" do
      visit project_merge_request_path(project, @merge_request)

      expect(page).to have_link(issue.to_reference)
    end
  end

  describe "for milestones" do
    before do
      @milestone = create(
        :milestone,
        project: project,
        title: "fix #{issue.to_reference}",
        description: "ask #{fred.to_reference} for details"
      )
    end

    it "renders title in milestones#index" do
      visit project_milestones_path(project)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders title in milestones#show" do
      visit project_milestone_path(project, @milestone)

      expect(page).to have_link(issue.to_reference)
    end

    it "renders description in milestones#show" do
      visit project_milestone_path(project, @milestone)

      expect(page).to have_link(fred.to_reference)
    end
  end
end
