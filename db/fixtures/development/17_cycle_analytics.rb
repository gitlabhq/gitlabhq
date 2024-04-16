# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require './spec/support/helpers/test_env'
require 'active_support/testing/time_helpers'
require './spec/support/helpers/cycle_analytics_helpers'
require './ee/db/seeds/shared/dora_metrics' if Gitlab.ee?

# Usage:
#
# Simple invocation always creates a new project:
#
# FILTER=cycle_analytics SEED_VSA=1 bundle exec rake db:seed_fu
#
# Create more issues/MRs:
#
# VSA_ISSUE_COUNT=100 FILTER=cycle_analytics SEED_VSA=1 bundle exec rake db:seed_fu
#
# Run for an existing project
#
# VSA_SEED_PROJECT_ID=10 FILTER=cycle_analytics SEED_VSA=1 bundle exec rake db:seed_fu

# rubocop:disable Rails/Output
class Gitlab::Seeder::CycleAnalytics # rubocop:disable Style/ClassAndModuleChildren
  include ActiveSupport::Testing::TimeHelpers
  include CycleAnalyticsHelpers

  attr_reader :project, :issues, :merge_requests, :developers

  FLAG = 'SEED_VSA'
  PERF_TEST = 'VSA_PERF_TEST'

  MAX_DURATIONS = { # in hours
    issue: 72,
    plan: 48,
    code: 72,
    test: 5,
    review: 72,
    deployment: 48,
    lead_time: 32
  }.freeze

  def self.seeder_based_on_env(project)
    if ENV[FLAG]
      new(project: project)
    elsif ENV[PERF_TEST]
      new(project: project, perf: true)
    end
  end

  def initialize(project: nil, perf: false)
    @project = project || create_new_vsm_project
    @issue_count = perf ? 1000 : ENV.fetch('VSA_ISSUE_COUNT', 5).to_i
    @issues = []
    @merge_requests = []
    @developers = []
  end

  def seed!
    unless project.repository_exists?
      puts
      puts 'WARNING'
      puts '======='
      puts "Seeding #{self.class} is not possible because the given project " \
           "(#{project.full_path}) doesn't have a repository."
      puts 'Try specifying a project with working repository or omit the VSA_SEED_PROJECT_ID parameter ' \
           'so the seed script will automatically create one.'
      puts

      return
    end

    seed_data!
  end

  private

  def seed_data!
    Sidekiq::Worker.skipping_transaction_check do
      create_developers!
      create_issues!

      seed_lead_time!
      seed_issue_stage!
      seed_plan_stage!
      seed_code_stage!
      seed_test_stage!
      seed_review_stage!
      seed_staging_stage!

      if Gitlab.ee?
        create_vulnerabilities_count_report!
        seed_dora_metrics!
        create_custom_value_stream!
        create_value_stream_aggregation(project.group)
      end

      puts "Successfully seeded '#{project.full_path}' for Value Stream Management!"
      puts "URL: #{Rails.application.routes.url_helpers.project_url(project)}"
    end
  end

  def create_custom_value_stream!
    [project.project_namespace.reload, project.group].each do |parent|
      Analytics::CycleAnalytics::ValueStreams::CreateService.new(
        current_user: admin,
        namespace: parent,
        params: { name: "vs #{suffix}", stages: Gitlab::Analytics::CycleAnalytics::DefaultStages.all }
      ).execute
    end
  end

  def seed_dora_metrics!
    Gitlab::Seeder::DoraMetrics.new(project: project).execute
  end

  def seed_issue_stage!
    issues.each do |issue|
      time = within_end_time(issue.created_at + rand(MAX_DURATIONS[:issue]).hours)

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

      first_mentioned_in_commit_at = within_end_time(plan_stage_start + rand(MAX_DURATIONS[:plan]).hours)
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
        created_at: within_end_time(issue.metrics.first_mentioned_in_commit_at + rand(MAX_DURATIONS[:code]).hours)
      )

      @merge_requests << merge_request

      MergeRequestsClosingIssues.create!(issue: issue, merge_request: merge_request)
    end
  end

  def seed_test_stage!
    merge_requests.each do |merge_request|
      pipeline = FactoryBot.create(:ci_pipeline, :success, project: project,
        partition_id: Ci::Pipeline.current_partition_value)
      build = FactoryBot.create(:ci_build, pipeline: pipeline, project: project, user: developers.sample)

      # Required because seeds run in a transaction and these are now
      # created in an `after_commit` hook.
      merge_request.ensure_metrics!

      merge_request.metrics.update!(
        latest_build_started_at: merge_request.created_at,
        latest_build_finished_at: within_end_time(merge_request.created_at + MAX_DURATIONS[:test].hours),
        pipeline_id: build.commit_id
      )
    end
  end

  def seed_review_stage!
    merge_requests.each do |merge_request|
      merge_request.metrics.update!(
        merged_at: within_end_time(merge_request.created_at + MAX_DURATIONS[:review].hours)
      )
    end
  end

  def seed_staging_stage!
    merge_requests.each do |merge_request|
      first_deployed_to_production_at = merge_request.metrics.merged_at + MAX_DURATIONS[:deployment].hours
      merge_request.metrics.update!(
        first_deployed_to_production_at: within_end_time(first_deployed_to_production_at)
      )
    end
  end

  def seed_lead_time!
    issues.each do |issue|
      created_at = issue.created_at - MAX_DURATIONS[:lead_time].hours
      issue.update!(created_at: created_at, closed_at: Time.now)
    end
  end

  def create_issues!
    @issue_count.times do
      travel_to(start_time + rand(5).days) do
        title = "#{FFaker::Product.brand}-#{suffix}"
        @issues << Issue.create!(project: project, title: title, author: developers.sample)
      end
    end
  end

  def create_vulnerabilities_count_report!
    4.times do |i|
      critical_count = rand(5..10)
      high_count = rand(5..10)

      [i.months.ago.end_of_month, i.months.ago.beginning_of_month].each do |date|
        FactoryBot.create(:vulnerability_historical_statistic,
          date: date,
          total: critical_count + high_count,
          critical: critical_count,
          high: high_count,
          project: project
        )
      end
    end
  end

  def create_developers!
    5.times do |i|
      user =
        ::User.create!(
          username: "vsm-user-#{i}-#{suffix}",
          name: "VSM User#{i}",
          email: "vsm-user-#{i}@#{suffix}.com",
          confirmed_at: DateTime.now,
          password: ::User.random_password
        ) do |user|
          user.assign_personal_namespace(Organizations::Organization.default_organization)
        end

      project.group&.add_developer(user)
      project.add_developer(user)

      @developers << user
    end

    project.group&.add_developer(admin)
    project.add_developer(admin)

    AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute
  end

  def create_new_vsm_project
    namespace = FactoryBot.create(
      :group,
      name: "Value Stream Management Group #{suffix}",
      path: "vsmg-#{suffix}"
    )
    project = FactoryBot.create(
      :project,
      :repository,
      name: "Value Stream Management Project #{suffix}",
      path: "vsmp-#{suffix}",
      creator: admin,
      namespace: namespace
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
  project_id = ENV['VSA_SEED_PROJECT_ID']
  project = Project.find(project_id) if project_id

  seeder = Gitlab::Seeder::CycleAnalytics.seeder_based_on_env(project)

  if seeder
    seeder.seed!
  else
    puts "Skipped. Use the `#{Gitlab::Seeder::CycleAnalytics::FLAG}` environment variable to enable."
  end
end
# rubocop:enable Rails/Output
