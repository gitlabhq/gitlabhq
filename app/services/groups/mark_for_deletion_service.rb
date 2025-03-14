# frozen_string_literal: true

module Groups # rubocop:disable Gitlab/BoundedContexts -- existing top-level module
  class MarkForDeletionService < Groups::BaseService
    # rubocop:disable Gitlab/NoCodeCoverageComment -- Tested in FOSS and fully overridden and tested in EE
    # :nocov
    def execute(async: true)
      service = ::Groups::DestroyService.new(group, current_user, params)

      async ? service.async_execute : service.execute
    end
    # :nocov:
    # rubocop:enable Gitlab/NoCodeCoverageComment
  end
end

Groups::MarkForDeletionService.prepend_mod
