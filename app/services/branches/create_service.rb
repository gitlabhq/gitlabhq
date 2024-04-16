# frozen_string_literal: true

module Branches
  class CreateService < BaseService
    def initialize(project, user = nil, params = {})
      super(project, user, params)

      @errors = []
    end

    def execute(branch_name, ref, create_default_branch_if_empty: true)
      result = validate_ref(ref)
      return result if result[:status] == :error

      create_default_branch if create_default_branch_if_empty && project.empty_repo?

      result = branch_validation_service.execute(branch_name)

      return result if result[:status] == :error

      create_branch(branch_name, ref)
    end

    def bulk_create(branches)
      reset_errors

      created_branches =
        branches
          .then { |branches| only_valid_branches(branches) }
          .then { |branches| create_branches(branches) }
          .then { |branches| expire_branches_cache(branches) }

      return error(errors) if errors.present?

      success(branches: created_branches)
    end

    private

    attr_reader :errors

    def reset_errors
      @errors = []
    end

    def only_valid_branches(branches)
      branches.select do |branch_name, _ref|
        result = branch_validation_service.execute(branch_name)

        if result[:status] == :error
          errors << result[:message]
          next
        end

        true
      end
    end

    def create_branches(branches)
      branches.filter_map do |branch_name, ref|
        result = create_branch(branch_name, ref, expire_cache: false)

        if result[:status] == :error
          errors << result[:message]
          next
        end

        result[:branch]
      end
    end

    def expire_branches_cache(branches)
      repository.expire_branches_cache if branches.present?

      branches
    end

    def create_branch(branch_name, ref, expire_cache: true)
      new_branch = repository.add_branch(current_user, branch_name, ref, expire_cache: expire_cache)

      if new_branch
        success(branch: new_branch)
      else
        error("Failed to create branch '#{branch_name}': invalid reference name '#{ref}'")
      end
    rescue Gitlab::Git::CommandError => e
      error("Failed to create branch '#{branch_name}': #{e}")
    rescue Gitlab::Git::PreReceiveError => e
      Gitlab::ErrorTracking.log_exception(e, pre_receive_message: e.raw_message, branch_name: branch_name, ref: ref)
      error(e.message)
    end

    def validate_ref(ref)
      return error('Ref is missing') if ref.blank?

      success
    end

    def create_default_branch
      project.repository.create_file(
        current_user,
        '/README.md',
        '',
        message: 'Add README.md',
        branch_name: project.default_branch_or_main
      )
    end

    def branch_validation_service
      @branch_validation_service ||= ::Branches::ValidateNewService.new(project)
    end
  end
end
