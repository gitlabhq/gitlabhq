# frozen_string_literal: true

module TestHooks
  class SystemService < TestHooks::BaseService
    include Gitlab::Utils::StrongMemoize

    private

    def data
      strong_memoize(:data) do
        case trigger
        when 'push_events', 'tag_push_events'
          Gitlab::DataBuilder::Push.sample_data
        when 'repository_update_events'
          Gitlab::DataBuilder::Repository.sample_data
        when 'merge_requests_events'
          merge_requests_events_data
        end
      end
    end

    def merge_requests_events_data
      merge_request = MergeRequest.of_projects(current_user.projects.select(:id)).last

      return { error: s_('TestHooks|Ensure one of your projects has merge requests.') } unless merge_request.present?

      merge_request.to_hook_data(current_user)
    end
  end
end
