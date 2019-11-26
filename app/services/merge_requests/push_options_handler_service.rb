# frozen_string_literal: true

module MergeRequests
  class PushOptionsHandlerService
    LIMIT = 10

    attr_reader :current_user, :errors, :changes,
                :project, :push_options, :target_project

    def initialize(project, current_user, changes, push_options)
      @project = project
      @target_project = @project.default_merge_request_target
      @current_user = current_user
      @changes = Gitlab::ChangesList.new(changes)
      @push_options = push_options
      @errors = []
    end

    def execute
      validate_service
      return self if errors.present?

      branches.each do |branch|
        execute_for_branch(branch)
      rescue Gitlab::Access::AccessDeniedError
        errors << 'User access was denied'
      rescue StandardError => e
        Gitlab::AppLogger.error(e)
        errors << 'An unknown error occurred'
      end

      self
    end

    private

    def branches
      changes_by_branch.keys
    end

    def changes_by_branch
      @changes_by_branch ||= changes.each_with_object({}) do |changes, result|
        next unless Gitlab::Git.branch_ref?(changes[:ref])

        # Deleted branch
        next if Gitlab::Git.blank_ref?(changes[:newrev])

        # Default branch
        branch_name = Gitlab::Git.branch_name(changes[:ref])
        next if branch_name == target_project.default_branch

        result[branch_name] = changes
      end
    end

    def validate_service
      errors << 'User is required' if current_user.nil?

      unless target_project.merge_requests_enabled?
        errors << "Merge requests are not enabled for project #{target_project.full_path}"
      end

      if branches.size > LIMIT
        errors << "Too many branches pushed (#{branches.size} were pushed, limit is #{LIMIT})"
      end

      if push_options[:target] && !target_project.repository.branch_exists?(push_options[:target])
        errors << "Branch #{push_options[:target]} does not exist"
      end
    end

    # Returns a Hash of branch => MergeRequest
    def merge_requests
      @merge_requests ||= MergeRequest.from_project(target_project)
                                      .opened
                                      .from_source_branches(branches)
                                      .index_by(&:source_branch)
    end

    def execute_for_branch(branch)
      merge_request = merge_requests[branch]

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

      # Use BuildService to assign the standard attributes of a merge request
      merge_request = ::MergeRequests::BuildService.new(
        project,
        current_user,
        create_params(branch)
      ).execute

      unless merge_request.errors.present?
        merge_request = ::MergeRequests::CreateService.new(
          project,
          current_user,
          merge_request.attributes.merge(assignees: merge_request.assignees,
                                         label_ids: merge_request.label_ids)
        ).execute
      end

      collect_errors_from_merge_request(merge_request) unless merge_request.persisted?
    end

    def update!(merge_request)
      merge_request = ::MergeRequests::UpdateService.new(
        target_project,
        current_user,
        update_params(merge_request)
      ).execute(merge_request)

      collect_errors_from_merge_request(merge_request) unless merge_request.valid?
    end

    def base_params
      params = {
        title: push_options[:title],
        description: push_options[:description],
        target_branch: push_options[:target],
        force_remove_source_branch: push_options[:remove_source_branch],
        label: push_options[:label],
        unlabel: push_options[:unlabel]
      }

      params.compact!

      params[:add_labels] = params.delete(:label).keys if params.has_key?(:label)
      params[:remove_labels] = params.delete(:unlabel).keys if params.has_key?(:unlabel)

      params
    end

    def merge_params(branch)
      return {} unless push_options.key?(:merge_when_pipeline_succeeds)

      {
        merge_when_pipeline_succeeds: push_options[:merge_when_pipeline_succeeds],
        merge_user: current_user,
        sha: changes_by_branch.dig(branch, :newrev)
      }
    end

    def create_params(branch)
      params = base_params

      params.merge!(
        assignees: [current_user],
        source_branch: branch,
        source_project: project,
        target_project: target_project
      )

      params.merge!(merge_params(branch))

      params[:target_branch] ||= target_project.default_branch

      params
    end

    def update_params(merge_request)
      base_params.merge(merge_params(merge_request.source_branch))
    end

    def collect_errors_from_merge_request(merge_request)
      merge_request.errors.full_messages.each do |error|
        errors << error
      end
    end
  end
end
