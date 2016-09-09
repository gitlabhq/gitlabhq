require 'sidekiq/testing'

class Gitlab::Seeder::CycleAnalytics
  def initialize(project)
    @project = project
    @user = User.find(1)
    stub_git_pre_receive!
  end

  # The GitLab API needn't be running for the fixtures to be
  # created. Since we're performing a number of git actions
  # here (like creating a branch or committing a file), we need
  # to disable the `pre_receive` hook in order to remove this
  # dependency on the GitLab API.
  def stub_git_pre_receive!
    GitHooksService.class_eval do
      def run_hook(name)
        [true, '']
      end
    end
  end

  def seed!
    Sidekiq::Testing.inline! do
      issues = create_issues(@project)

      # Stage 1
      Timecop.travel 5.days.from_now
      add_milestones_and_list_labels(issues)
      Timecop.return

      # Stage 2
      Timecop.travel 10.days.from_now
      branches = mention_in_commits(issues)
      Timecop.return

      # Stage 3
      Timecop.travel 15.days.from_now
      merge_requests = create_merge_requests_closing_issues(issues, branches)
      Timecop.return

      # Stage 4
      Timecop.travel 20.days.from_now
      run_builds(merge_requests)
      Timecop.return

      # Stage 5
      Timecop.travel 25.days.from_now
      merge_merge_requests(merge_requests)
      Timecop.return

      # Stage 6 / 7
      Timecop.travel 30.days.from_now
      deploy_to_production(merge_requests)
      Timecop.return
    end

    print '.'
  end

  private

  def create_issues(project)
    Array.new(5) do
      issue_params = {
        title: "Cycle Analytics: #{FFaker::Lorem.sentence(6)}",
        description: FFaker::Lorem.sentence,
        state: 'opened',
        assignee: @project.team.users.sample
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
        list_label = FactoryGirl.create(:label, title: label_name, project: issue.project)
        FactoryGirl.create(:list, board: FactoryGirl.create(:board, project: issue.project), label: list_label)
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

      options = {
        committer: issue.project.repository.user_to_committer(@user),
        author: issue.project.repository.user_to_committer(@user),
        commit: { message: "Commit for ##{issue.iid}", branch: branch_name, update_ref: true },
        file: { content: "content", path: filename, update: false }
      }

      commit_sha = Gitlab::Git::Blob.commit(issue.project.repository, options)
      commit = issue.project.repository.commit(commit_sha)
      commit.create_cross_references!

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
      pipeline = service.execute(ignore_skip_ci: true, save_on_errors: false)

      pipeline.run!
      Timecop.travel rand(1..6).hours.from_now
      pipeline.succeed!
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
      Timecop.travel 12.hours.from_now

      CreateDeploymentService.new(merge_request.project, @user, {
                                    environment: 'production',
                                    ref: 'master',
                                    tag: false,
                                    sha: @project.repository.commit('master').sha
                                  }).execute
    end
  end
end

Gitlab::Seeder.quiet do
  Project.all.each do |project|
    seeder = Gitlab::Seeder::CycleAnalytics.new(project)
    seeder.seed!
  end
end
