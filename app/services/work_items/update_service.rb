# frozen_string_literal: true

module WorkItems
  class UpdateService < ::Issues::UpdateService
    private

    def after_update(issuable)
      super

      GraphqlTriggers.issuable_title_updated(issuable) if issuable.previous_changes.key?(:title)
    end
  end
end
