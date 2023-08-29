# frozen_string_literal: true

module Submodules
  class UpdateService < Commits::CreateService
    include Gitlab::Utils::StrongMemoize

    def initialize(*args)
      super

      @start_branch = @branch_name
      @commit_sha = params[:commit_sha].presence
      @submodule = params[:submodule].presence
      @commit_message = params[:commit_message].presence || "Update submodule #{@submodule} with oid #{@commit_sha}"
    end

    def validate!
      super

      raise ValidationError, 'The repository is empty' if repository.empty?
    end

    def execute
      super
    rescue StandardError => e
      error(e.message)
    end

    def create_commit!
      repository.update_submodule(
        current_user,
        @submodule,
        @commit_sha,
        message: @commit_message,
        branch: @branch_name
      )
    rescue ArgumentError, TypeError
      raise ValidationError, 'Invalid parameters'
    end
  end
end
