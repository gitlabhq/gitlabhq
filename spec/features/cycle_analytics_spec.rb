require 'spec_helper'

feature 'Cycle Analytics', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:guest) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(issue) }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha) }

  context 'as an allowed user' do
    context 'when project is new' do
      before  do
        project.team << [user, :master]
        login_as(user)
        visit namespace_project_cycle_analytics_path(project.namespace, project)
        wait_for_ajax
      end

      it 'shows introductory message' do
        expect(page).to have_content('Introducing Cycle Analytics')
      end

      it 'shows active stage with empty message' do
        expect(page).to have_selector('.stage-nav-item.active', text: 'Issue')
        expect(page).to have_content("We don't have enough data to show this stage.")
      end
    end

    context "when there's cycle analytics data" do
      before do
        project.team << [user, :master]

        allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return([issue])
        create_cycle
        deploy_master

        login_as(user)
        visit namespace_project_cycle_analytics_path(project.namespace, project)
      end

      it 'shows data on each stage' do
        expect_issue_to_be_present

        click_stage('Plan')
        expect(find('.stage-events')).to have_content(mr.commits.last.title)

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
    end
  end

  context "as a guest" do
    before do
      project.team << [guest, :guest]

      allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return([issue])
      create_cycle
      deploy_master

      login_as(guest)
      visit namespace_project_cycle_analytics_path(project.namespace, project)
      wait_for_ajax
    end

    it 'needs permissions to see restricted stages' do
      expect(find('.stage-events')).to have_content(issue.title)

      click_stage('Code')
      expect(find('.stage-events')).to have_content('You need permission.')

      click_stage('Review')
      expect(find('.stage-events')).to have_content('You need permission.')
    end
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

  def create_cycle
    issue.update(milestone: milestone)
    pipeline.run

    @build = create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(issue)
    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)
  end

  def click_stage(stage_name)
    find('.stage-nav li', text: stage_name).click
    wait_for_ajax
  end
end
