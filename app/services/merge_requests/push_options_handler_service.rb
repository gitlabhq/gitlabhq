# frozen_string_literal: true

module MergeRequests
  class PushOptionsHandlerService
    Error = Class.new(StandardError)

    LIMIT = 10

    attr_reader :branches, :changes_by_branch, :current_user, :errors,
                :project, :push_options

    def initialize(project, current_user, changes, push_options)
      @project = project
      @current_user = current_user
      @changes_by_branch = parse_changes(changes)
      @push_options = push_options
      @errors = []
      @branches = @changes_by_branch.keys

      raise Error, 'User is required' if @current_user.nil?

      unless @project.merge_requests_enabled?
        raise Error, 'Merge requests are not enabled for project'
      end

      if @branches.size > LIMIT
        raise Error, "Too many branches pushed (#{@branches.size} were pushed, limit is #{LIMIT})"
      end

      if @push_options[:target] && !@project.repository.branch_exists?(@push_options[:target])
        raise Error, "Branch #{@push_options[:target]} does not exist"
      end
    end

    def execute
      branches.each do |branch|
        execute_for_branch(branch)
      end

      self
    end

    private

    # Parses changes in the push.
    # Returns a hash of branch => changes_list
    def parse_changes(raw_changes)
      Gitlab::ChangesList.new(raw_changes).each_with_object({}) do |change, changes|
        next unless Gitlab::Git.branch_ref?(change[:ref])

        # Deleted branch
        next if Gitlab::Git.blank_ref?(change[:newrev])

        # Default branch
        branch_name = Gitlab::Git.branch_name(change[:ref])
        next if branch_name == project.default_branch

        changes[branch_name] = change
      end
    end

    def merge_requests
      @merge_requests ||= MergeRequest.from_project(@project)
                                      .opened
                                      .from_source_branches(@branches)
                                      .to_a # fetch now
    end

    def execute_for_branch(branch)
      merge_request = merge_requests.find { |mr| mr.source_branch == branch }

      if merge_request
        update!(merge_request)
      else
        create!(branch)
      end
    end

    def create!(branch)
      unless push_options[:create]
        errors << "A merge_request.create push option is required to create a merge request for branch #{branch}"
        return
      end

      merge_request = ::MergeRequests::CreateService.new(
        project,
        current_user,
        create_params(branch)
      ).execute

      collect_errors_from_merge_request(merge_request) unless merge_request.persisted?
    end

    def update!(merge_request)
      merge_request = ::MergeRequests::UpdateService.new(
        project,
        current_user,
        update_params
      ).execute(merge_request)

      collect_errors_from_merge_request(merge_request) unless merge_request.valid?
    end

    def create_params(branch)
      change = changes_by_branch.fetch(branch)

      commits = project.repository.commits_between(project.default_branch, change[:newrev])
      commits = CommitCollection.new(project, commits)
      commit = commits.without_merge_commits.first

      params = {
        assignee: current_user,
        source_branch: branch,
        target_branch: push_options[:target] || project.default_branch,
        title: commit&.title&.strip || 'New Merge Request',
        description: commit&.description&.strip
      }

      if push_options.key?(:merge_when_pipeline_succeeds)
        params.merge!(
          merge_when_pipeline_succeeds: push_options[:merge_when_pipeline_succeeds],
          merge_user: current_user
        )
      end

      params
    end

    def update_params
      params = {}

      if push_options.key?(:merge_when_pipeline_succeeds)
        params.merge!(
          merge_when_pipeline_succeeds: push_options[:merge_when_pipeline_succeeds],
          merge_user: current_user
        )
      end

      if push_options.key?(:target)
        params[:target_branch] = push_options[:target]
      end

      params
    end

    def collect_errors_from_merge_request(merge_request)
      errors << merge_request.errors.full_messages.to_sentence
    end
  end
end
