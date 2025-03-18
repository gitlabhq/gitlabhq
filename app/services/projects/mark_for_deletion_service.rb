# frozen_string_literal: true

module Projects
  class MarkForDeletionService < BaseService
    # rubocop:disable Gitlab/NoCodeCoverageComment -- Tested in FOSS and fully overridden and tested in EE
    # :nocov:
    def execute(async: true)
      service = ::Projects::DestroyService.new(project, current_user, params)

      async ? service.async_execute : service.execute
    end
    # :nocov:
    # rubocop:enable Gitlab/NoCodeCoverageComment
  end
end

Projects::MarkForDeletionService.prepend_mod
