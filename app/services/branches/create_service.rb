# frozen_string_literal: true

module Branches
  class CreateService < BaseService
    def execute(branch_name, ref, create_default_branch_if_empty: true)
      create_default_branch if create_default_branch_if_empty && project.empty_repo?

      result = ::Branches::ValidateNewService.new(project).execute(branch_name)

      return result if result[:status] == :error

      begin
        new_branch = repository.add_branch(current_user, branch_name, ref)
      rescue Gitlab::Git::CommandError => e
        return error("Failed to create branch '#{branch_name}': #{e}")
      end

      if new_branch
        success(new_branch)
      else
        error("Failed to create branch '#{branch_name}': invalid reference name '#{ref}'")
      end
    rescue Gitlab::Git::PreReceiveError => e
      Gitlab::ErrorTracking.track_exception(e, pre_receive_message: e.raw_message, branch_name: branch_name, ref: ref)
      error(e.message)
    end

    def success(branch)
      super().merge(branch: branch)
    end

    private

    def create_default_branch
      project.repository.create_file(
        current_user,
        '/README.md',
        '',
        message: 'Add README.md',
        branch_name: project.default_branch_or_main
      )
    end
  end
end
