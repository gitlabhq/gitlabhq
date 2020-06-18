# frozen_string_literal: true

module ResourceEvents
  class ChangeStateService
    attr_reader :resource, :user

    def initialize(user:, resource:)
      @user, @resource = user, resource
    end

    def execute(state)
      ResourceStateEvent.create(
        user: user,
        issue: issue,
        merge_request: merge_request,
        state: ResourceStateEvent.states[state],
        created_at: Time.zone.now)

      resource.expire_note_etag_cache
    end

    private

    def issue
      return unless resource.is_a?(Issue)

      resource
    end

    def merge_request
      return unless resource.is_a?(MergeRequest)

      resource
    end
  end
end
