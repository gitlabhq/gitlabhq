require './spec/support/sidekiq'
require './spec/support/helpers/test_env'

class Gitlab::Seeder::CycleAnalytics
  def initialize(project, perf: false)
    @project = project
    @user = User.admins.first
    @issue_count = perf ? 1000 : 5
    stub_git_pre_receive!
  end

  # The GitLab API needn't be running for the fixtures to be
  # created. Since we're performing a number of git actions
  # here (like creating a branch or committing a file), we need
  # to disable the `pre_receive` hook in order to remove this
  # dependency on the GitLab API.
  def stub_git_pre_receive!
    Gitlab::Git::HooksService.class_eval do
      def run_hook(name)
        [true, '']
      end
    end
  end

  def seed_metrics!
    @issue_count.times do |index|
      # Issue
      Timecop.travel 5.days.from_now
      title = "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"
      issue = Issue.create(project: @project, title: title, author: @user)
      issue_metrics = issue.metrics

      # Milestones / Labels
      Timecop.travel 5.days.from_now
      if index.even?
        issue_metrics.first_associated_with_milestone_at = rand(6..12).hours.from_now
      else
        issue_metrics.first_added_to_board_at = rand(6..12).hours.from_now
      end

      # Commit
      Timecop.travel 5.days.from_now
      issue_metrics.first_mentioned_in_commit_at = rand(6..12).hours.from_now

      # MR
      Timecop.travel 5.days.from_now
      branch_name = "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"
      @project.repository.add_branch(@user, branch_name, 'master')
      merge_request = MergeRequest.create(target_project: @project, source_project: @project, source_branch: branch_name, target_branch: 'master', title: branch_name, author: @user)
      merge_request_metrics = merge_request.metrics

      # MR closing issues
      Timecop.travel 5.days.from_now
      MergeRequestsClosingIssues.create!(issue: issue, merge_request: merge_request)

      # Merge
      Timecop.travel 5.days.from_now
      merge_request_metrics.merged_at = rand(6..12).hours.from_now

      # Start build
      Timecop.travel 5.days.from_now
      merge_request_metrics.latest_build_started_at = rand(6..12).hours.from_now

      # Finish build
      Timecop.travel 5.days.from_now
      merge_request_metrics.latest_build_finished_at = rand(6..12).hours.from_now

      # Deploy to production
      Timecop.travel 5.days.from_now
      merge_request_metrics.first_deployed_to_production_at = rand(6..12).hours.from_now

      issue_metrics.save!
      merge_request_metrics.save!

      print '.'
    end
  end

  def seed!
    Sidekiq::Worker.skipping_transaction_check do
      Sidekiq::Testing.inline! do
        issues = create_issues
        puts '.'

        # Stage 1
        Timecop.travel 5.days.from_now
        add_milestones_and_list_labels(issues)
        print '.'

        # Stage 2
        Timecop.travel 5.days.from_now
        branches = mention_in_commits(issues)
        print '.'

        # Stage 3
        Timecop.travel 5.days.from_now
        merge_requests = create_merge_requests_closing_issues(issues, branches)
        print '.'

        # Stage 4
        Timecop.travel 5.days.from_now
        run_builds(merge_requests)
        print '.'

        # Stage 5
        Timecop.travel 5.days.from_now
        merge_merge_requests(merge_requests)
        print '.'

        # Stage 6 / 7
        Timecop.travel 5.days.from_now
        deploy_to_production(merge_requests)
        print '.'
      end
    end

    print '.'
  end

  private

  def create_issues
    Array.new(@issue_count) do
      issue_params = {
        title: "Cycle Analytics: #{FFaker::Lorem.sentence(6)}",
        description: FFaker::Lorem.sentence,
        state: 'opened',
        assignees: [@project.team.users.sample]
      }

      Issues::CreateService.new(@project, @project.team.users.sample, issue_params).execute
    end
  end

  def add_milestones_and_list_labels(issues)
    issues.shuffle.map.with_index do |issue, index|
      Timecop.travel 12.hours.from_now

      if index.even?
        issue.update(milestone: @project.milestones.sample)
      else
        label_name = "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"
        list_label = FactoryBot.create(:label, title: label_name, project: issue.project)
        FactoryBot.create(:list, board: FactoryBot.create(:board, project: issue.project), label: list_label)
        issue.update(labels: [list_label])
      end

      issue
    end
  end

  def mention_in_commits(issues)
    issues.map do |issue|
      Timecop.travel 12.hours.from_now

      branch_name = filename = "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"

      issue.project.repository.add_branch(@user, branch_name, 'master')

      commit_sha = issue.project.repository.create_file(@user, filename, "content", message: "Commit for #{issue.to_reference}", branch_name: branch_name)
      issue.project.repository.commit(commit_sha)

      GitPushService.new(issue.project,
                         @user,
                         oldrev: issue.project.repository.commit("master").sha,
                         newrev: commit_sha,
                         ref: 'refs/heads/master').execute

      branch_name
    end
  end

  def create_merge_requests_closing_issues(issues, branches)
    issues.zip(branches).map do |issue, branch|
      Timecop.travel 12.hours.from_now

      opts = {
        title: 'Cycle Analytics merge_request',
        description: "Fixes #{issue.to_reference}",
        source_branch: branch,
        target_branch: 'master'
      }

      MergeRequests::CreateService.new(issue.project, @user, opts).execute
    end
  end

  def run_builds(merge_requests)
    merge_requests.each do |merge_request|
      Timecop.travel 12.hours.from_now

      service = Ci::CreatePipelineService.new(merge_request.project,
                                              @user,
                                              ref: "refs/heads/#{merge_request.source_branch}")
      pipeline = service.execute(:push, ignore_skip_ci: true, save_on_errors: false)

      pipeline.run!
      Timecop.travel rand(1..6).hours.from_now
      pipeline.succeed!

      PipelineMetricsWorker.new.perform(pipeline.id)
    end
  end

  def merge_merge_requests(merge_requests)
    merge_requests.each do |merge_request|
      Timecop.travel 12.hours.from_now

      MergeRequests::MergeService.new(merge_request.project, @user).execute(merge_request)
    end
  end

  def deploy_to_production(merge_requests)
    merge_requests.each do |merge_request|
      next unless merge_request.head_pipeline

      Timecop.travel 12.hours.from_now

      job = merge_request.head_pipeline.builds.where.not(environment: nil).last

      CreateDeploymentService.new(job).execute
    end
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_CYCLE_ANALYTICS'

  if ENV[flag]
    Project.find_each do |project|
      # This seed naively assumes that every project has a repository, and every
      # repository has a `master` branch, which may be the case for a pristine
      # GDK seed, but is almost never true for a GDK that's actually had
      # development performed on it.
      next unless project.repository_exists?
      next unless project.repository.commit('master')

      seeder = Gitlab::Seeder::CycleAnalytics.new(project)
      seeder.seed!
    end
  elsif ENV['CYCLE_ANALYTICS_PERF_TEST']
    seeder = Gitlab::Seeder::CycleAnalytics.new(Project.order(:id).first, perf: true)
    seeder.seed!
  elsif ENV['CYCLE_ANALYTICS_POPULATE_METRICS_DIRECTLY']
    seeder = Gitlab::Seeder::CycleAnalytics.new(Project.order(:id).first, perf: true)
    seeder.seed_metrics!
  else
    puts "Skipped. Use the `#{flag}` environment variable to enable."
  end
end
