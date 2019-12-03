# frozen_string_literal: true

module Branches
  class CreateService < BaseService
    def execute(branch_name, ref, create_master_if_empty: true)
      create_master_branch if create_master_if_empty && project.empty_repo?

      result = ::Branches::ValidateNewService.new(project).execute(branch_name)

      return result if result[:status] == :error

      new_branch = repository.add_branch(current_user, branch_name, ref)

      if new_branch
        success(new_branch)
      else
        error("Invalid reference name: #{branch_name}")
      end
    rescue Gitlab::Git::PreReceiveError => ex
      error(ex.message)
    end

    def success(branch)
      super().merge(branch: branch)
    end

    private

    def create_master_branch
      project.repository.create_file(
        current_user,
        '/README.md',
        '',
        message: 'Add README.md',
        branch_name: 'master'
      )
    end
  end
end
