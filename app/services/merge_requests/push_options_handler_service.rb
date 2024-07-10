# frozen_string_literal: true

module MergeRequests
  class PushOptionsHandlerService < ::BaseProjectService
    LIMIT = 10

    attr_reader :errors, :changes, :push_options, :target_project

    def initialize(project:, current_user:, changes:, push_options:, params: {})
      super(project: project, current_user: current_user, params: params)

      @target_project = if push_options[:target_project]
                          Project.find_by_full_path(push_options[:target_project])
                        else
                          @project.default_merge_request_target
                        end

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
      if current_user.nil?
        errors << 'User is required'
        return
      end

      unless current_user&.can?(:read_code, target_project)
        errors << 'User access was denied'
        return
      end

      unless project == target_project || project.in_fork_network_of?(target_project)
        errors << "Projects #{project.full_path} and #{target_project.full_path} are not in the same network"
      end

      unless target_project.merge_requests_enabled?
        errors << "Merge requests are not enabled for project #{target_project.full_path}"
      end

      if branches.size > LIMIT
        errors << "Too many branches pushed (#{branches.size} were pushed, limit is #{LIMIT})"
      end

      if push_options[:target] && !target_project.repository.branch_exists?(push_options[:target])
        errors << "Target branch #{target_project.full_path}:#{push_options[:target]} does not exist"
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
        project: project,
        current_user: current_user,
        params: create_params(branch)
      ).execute

      unless merge_request.errors.present?
        merge_request = ::MergeRequests::CreateService.new(
          project: project,
          current_user: current_user,
          params: merge_request.attributes.merge(
            assignee_ids: merge_request.assignee_ids,
            label_ids: merge_request.label_ids
          )
        ).execute
      end

      collect_errors_from_merge_request(merge_request) unless merge_request.persisted?
    end

    def update!(merge_request)
      merge_request = ::MergeRequests::UpdateService.new(
        project: target_project,
        current_user: current_user,
        params: update_params(merge_request)
      ).execute(merge_request)

      collect_errors_from_merge_request(merge_request) unless merge_request.valid?
    end

    def base_params
      params = {
        title: push_options[:title],
        description: push_options[:description],
        draft: push_options[:draft],
        target_branch: push_options[:target],
        force_remove_source_branch: push_options[:remove_source_branch],
        squash: push_options[:squash],
        label: push_options[:label],
        unlabel: push_options[:unlabel],
        assign: push_options[:assign],
        unassign: push_options[:unassign]
      }

      params.compact!

      params[:add_labels] = params.delete(:label).keys if params.has_key?(:label)
      params[:remove_labels] = params.delete(:unlabel).keys if params.has_key?(:unlabel)

      params[:add_assignee_ids] = convert_to_user_ids(params.delete(:assign).keys) if params.has_key?(:assign)
      params[:remove_assignee_ids] = convert_to_user_ids(params.delete(:unassign).keys) if params.has_key?(:unassign)

      if push_options[:milestone]
        milestone = Milestone.for_projects_and_groups(@project, @project.ancestors_upto)&.find_by_name(push_options[:milestone])
        params[:milestone_id] = milestone.id if milestone
      end

      if params.key?(:description)
        params[:description] = params[:description].gsub('\n', "\n")
      end

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
        assignee_ids: [current_user.id],
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

    def convert_to_user_ids(ids_or_usernames)
      ids, usernames = ids_or_usernames.partition { |id_or_username| id_or_username.is_a?(Numeric) || id_or_username.match?(/\A\d+\z/) }
      ids += User.by_username(usernames).pluck(:id) unless usernames.empty? # rubocop:disable CodeReuse/ActiveRecord
      ids
    end

    def collect_errors_from_merge_request(merge_request)
      merge_request.errors.full_messages.each do |error|
        errors << error
      end
    end
  end
end
