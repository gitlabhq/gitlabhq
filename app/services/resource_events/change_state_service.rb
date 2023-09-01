# frozen_string_literal: true

module ResourceEvents
  class ChangeStateService
    attr_reader :resource, :user

    def initialize(user:, resource:)
      @user = user
      @resource = resource
    end

    def execute(params)
      @params = params

      ResourceStateEvent.create(
        user: user,
        resource.noteable_target_type_name => resource,
        source_commit: commit_id_of(mentionable_source),
        source_merge_request_id: merge_request_id_of(mentionable_source),
        state: ResourceStateEvent.states[state],
        close_after_error_tracking_resolve: close_after_error_tracking_resolve,
        close_auto_resolve_prometheus_alert: close_auto_resolve_prometheus_alert,
        created_at: resource.system_note_timestamp
      )

      resource.broadcast_notes_changed
    end

    private

    attr_reader :params

    def close_auto_resolve_prometheus_alert
      params[:close_auto_resolve_prometheus_alert] || false
    end

    def close_after_error_tracking_resolve
      params[:close_after_error_tracking_resolve] || false
    end

    def state
      params[:status]
    end

    def mentionable_source
      params[:mentionable_source]
    end

    def commit_id_of(mentionable_source)
      return unless mentionable_source.is_a?(Commit)

      mentionable_source.id[0...40]
    end

    def merge_request_id_of(mentionable_source)
      return unless mentionable_source.is_a?(MergeRequest)

      mentionable_source.id
    end
  end
end
