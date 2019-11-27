# frozen_string_literal: true

require 'spec_helper'

describe 'Cycle Analytics', :js do
  let(:user) { create(:user) }
  let(:guest) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  context 'as an allowed user' do
    context 'when project is new' do
      before do
        project.add_maintainer(user)

        sign_in(user)

        visit project_cycle_analytics_path(project)
        wait_for_requests
      end

      it 'shows introductory message' do
        expect(page).to have_content('Introducing Cycle Analytics')
      end

      it 'shows pipeline summary' do
        expect(new_issues_counter).to have_content('-')
        expect(commits_counter).to have_content('-')
        expect(deploys_counter).to have_content('-')
      end

      it 'shows active stage with empty message' do
        expect(page).to have_selector('.stage-nav-item.active', text: 'Issue')
        expect(page).to have_content("We don't have enough data to show this stage.")
      end
    end

    context "when there's cycle analytics data" do
      before do
        allow_next_instance_of(Gitlab::ReferenceExtractor) do |instance|
          allow(instance).to receive(:issues).and_return([issue])
        end
        project.add_maintainer(user)

        @build = create_cycle(user, project, issue, mr, milestone, pipeline)
        deploy_master(user, project)

        sign_in(user)
        visit project_cycle_analytics_path(project)
      end

      it 'shows pipeline summary' do
        expect(new_issues_counter).to have_content('1')
        expect(commits_counter).to have_content('2')
        expect(deploys_counter).to have_content('1')
      end

      it 'shows data on each stage', :sidekiq_might_not_need_inline do
        expect_issue_to_be_present

        click_stage('Plan')
        expect_issue_to_be_present

        click_stage('Code')
        expect_merge_request_to_be_present

        click_stage('Test')
        expect_build_to_be_present

        click_stage('Review')
        expect_merge_request_to_be_present

        click_stage('Staging')
        expect_build_to_be_present

        click_stage('Production')
        expect_issue_to_be_present
      end

      context "when I change the time period observed" do
        before do
          _two_weeks_old_issue = create(:issue, project: project, created_at: 2.weeks.ago)

          click_button('Last 30 days')
          click_link('Last 7 days')
          wait_for_requests
        end

        it 'shows only relevant data' do
          expect(new_issues_counter).to have_content('1')
        end
      end
    end
  end

  context "as a guest" do
    before do
      project.add_developer(user)
      project.add_guest(guest)

      allow_next_instance_of(Gitlab::ReferenceExtractor) do |instance|
        allow(instance).to receive(:issues).and_return([issue])
      end
      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)

      sign_in(guest)
      visit project_cycle_analytics_path(project)
      wait_for_requests
    end

    it 'does not show the commit stats' do
      expect(page).to have_no_selector(:xpath, commits_counter_selector)
    end

    it 'needs permissions to see restricted stages' do
      expect(find('.stage-events')).to have_content(issue.title)

      click_stage('Code')
      expect(find('.stage-events')).to have_content('You need permission.')

      click_stage('Review')
      expect(find('.stage-events')).to have_content('You need permission.')
    end
  end

  def new_issues_counter
    find(:xpath, "//p[contains(text(),'New Issue')]/preceding-sibling::h3")
  end

  def commits_counter_selector
    "//p[contains(text(),'Commits')]/preceding-sibling::h3"
  end

  def commits_counter
    find(:xpath, commits_counter_selector)
  end

  def deploys_counter
    find(:xpath, "//p[contains(text(),'Deploy')]/preceding-sibling::h3")
  end

  def expect_issue_to_be_present
    expect(find('.stage-events')).to have_content(issue.title)
    expect(find('.stage-events')).to have_content(issue.author.name)
    expect(find('.stage-events')).to have_content("##{issue.iid}")
  end

  def expect_build_to_be_present
    expect(find('.stage-events')).to have_content(@build.ref)
    expect(find('.stage-events')).to have_content(@build.short_sha)
    expect(find('.stage-events')).to have_content("##{@build.id}")
  end

  def expect_merge_request_to_be_present
    expect(find('.stage-events')).to have_content(mr.title)
    expect(find('.stage-events')).to have_content(mr.author.name)
    expect(find('.stage-events')).to have_content("!#{mr.iid}")
  end

  def click_stage(stage_name)
    find('.stage-nav li', text: stage_name).click
    wait_for_requests
  end
end
