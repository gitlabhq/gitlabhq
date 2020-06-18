# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require './spec/support/helpers/test_env'

# Usage:
#
# Simple invocation always creates a new project:
#
# FILTER=cycle_analytics SEED_CYCLE_ANALYTICS=1 bundle exec rake db:seed_fu
#
# Create more issues/MRs:
#
# CYCLE_ANALYTICS_ISSUE_COUNT=100 FILTER=cycle_analytics SEED_CYCLE_ANALYTICS=1 bundle exec rake db:seed_fu
#
# Run for an existing project
#
# CYCLE_ANALYTICS_SEED_PROJECT_ID=10 FILTER=cycle_analytics SEED_CYCLE_ANALYTICS=1 bundle exec rake db:seed_fu

class Gitlab::Seeder::CycleAnalytics
  attr_reader :project, :issues, :merge_requests, :developers

  FLAG = 'SEED_CYCLE_ANALYTICS'
  PERF_TEST = 'CYCLE_ANALYTICS_PERF_TEST'

  ISSUE_STAGE_MAX_DURATION_IN_HOURS = 72
  PLAN_STAGE_MAX_DURATION_IN_HOURS = 48
  CODE_STAGE_MAX_DURATION_IN_HOURS = 72
  TEST_STAGE_MAX_DURATION_IN_HOURS = 5
  REVIEW_STAGE_MAX_DURATION_IN_HOURS = 72
  DEPLOYMENT_MAX_DURATION_IN_HOURS = 48

  def self.seeder_based_on_env(project)
    if ENV[FLAG]
      self.new(project: project)
    elsif ENV[PERF_TEST]
      self.new(project: project, perf: true)
    end
  end

  def initialize(project: nil, perf: false)
    @project = project || create_new_vsm_project
    @issue_count = perf ? 1000 : ENV.fetch('CYCLE_ANALYTICS_ISSUE_COUNT', 5).to_i
    @issues = []
    @merge_requests = []
    @developers = []
  end

  def seed!
    create_developers!
    create_issues!

    seed_issue_stage!
    seed_plan_stage!
    seed_code_stage!
    seed_test_stage!
    seed_review_stage!
    seed_staging_stage!

    puts "Successfully seeded '#{project.full_path}' for Value Stream Management!"
    puts "URL: #{Rails.application.routes.url_helpers.project_url(project)}"
  end

  private

  def seed_issue_stage!
    issues.each do |issue|
      time = within_end_time(issue.created_at + rand(ISSUE_STAGE_MAX_DURATION_IN_HOURS).hours)

      if issue.id.even?
        issue.metrics.update!(first_associated_with_milestone_at: time)
      else
        issue.metrics.update!(first_added_to_board_at: time)
      end
    end
  end

  def seed_plan_stage!
    issues.each do |issue|
      plan_stage_start = issue.metrics.first_associated_with_milestone_at || issue.metrics.first_added_to_board_at

      first_mentioned_in_commit_at = within_end_time(plan_stage_start + rand(PLAN_STAGE_MAX_DURATION_IN_HOURS).hours)
      issue.metrics.update!(first_mentioned_in_commit_at: first_mentioned_in_commit_at)
    end
  end

  def seed_code_stage!
    issues.each do |issue|
      merge_request = FactoryBot.create(
        :merge_request,
        target_project: project,
        source_project: project,
        source_branch: "#{issue.iid}-feature-branch",
        target_branch: 'master',
        author: developers.sample,
        created_at: within_end_time(issue.metrics.first_mentioned_in_commit_at + rand(CODE_STAGE_MAX_DURATION_IN_HOURS).hours)
      )

      @merge_requests << merge_request

      MergeRequestsClosingIssues.create!(issue: issue, merge_request: merge_request)
    end
  end

  def seed_test_stage!
    merge_requests.each do |merge_request|
      pipeline = FactoryBot.create(:ci_pipeline, :success, project: project)
      build = FactoryBot.create(:ci_build, pipeline: pipeline, project: project, user: developers.sample)

      # Required because seeds run in a transaction and these are now
      # created in an `after_commit` hook.
      merge_request.ensure_metrics

      merge_request.metrics.update!(
        latest_build_started_at: merge_request.created_at,
        latest_build_finished_at: within_end_time(merge_request.created_at + TEST_STAGE_MAX_DURATION_IN_HOURS.hours),
        pipeline_id: build.commit_id
      )
    end
  end

  def seed_review_stage!
    merge_requests.each do |merge_request|
      merge_request.metrics.update!(merged_at: within_end_time(merge_request.created_at + REVIEW_STAGE_MAX_DURATION_IN_HOURS.hours))
    end
  end

  def seed_staging_stage!
    merge_requests.each do |merge_request|
      merge_request.metrics.update!(first_deployed_to_production_at: within_end_time(merge_request.metrics.merged_at + DEPLOYMENT_MAX_DURATION_IN_HOURS.hours))
    end
  end

  def create_issues!
    @issue_count.times do
      Timecop.travel start_time + rand(5).days do
        title = "#{FFaker::Product.brand}-#{suffix}"
        @issues << Issue.create!(project: project, title: title, author: developers.sample)
      end
    end
  end

  def create_developers!
    5.times do |i|
      user = FactoryBot.create(
        :user,
        name: "VSM User#{i}",
        username: "vsm-user-#{i}-#{suffix}",
        email: "vsm-user-#{i}@#{suffix}.com"
      )

      project.group.add_developer(user)
      project.add_developer(user)

      @developers << user
    end
  end

  def create_new_vsm_project
    project = FactoryBot.create(
      :project,
      name: "Value Stream Management Project #{suffix}",
      path: "vsmp-#{suffix}",
      creator: admin,
      namespace: FactoryBot.create(
        :group,
        name: "Value Stream Management Group #{suffix}",
        path: "vsmg-#{suffix}"
      )
    )

    project.create_repository
    project
  end

  def admin
    @admin ||= User.admins.first
  end

  def suffix
    @suffix ||= Time.now.to_i
  end

  def start_time
    @start_time ||= 25.days.ago
  end

  def end_time
    @end_time ||= Time.now
  end

  def within_end_time(time)
    [time, end_time].min
  end
end

Gitlab::Seeder.quiet do
  project_id = ENV['CYCLE_ANALYTICS_SEED_PROJECT_ID']
  project = Project.find(project_id) if project_id

  seeder = Gitlab::Seeder::CycleAnalytics.seeder_based_on_env(project)

  if seeder
    seeder.seed!
  else
    puts "Skipped. Use the `#{Gitlab::Seeder::CycleAnalytics::FLAG}` environment variable to enable."
  end
end
