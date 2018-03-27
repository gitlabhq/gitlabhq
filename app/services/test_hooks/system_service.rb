module TestHooks
  class SystemService < TestHooks::BaseService
    private

    def push_events_data
      Gitlab::DataBuilder::Push.sample_data
    end

    def tag_push_events_data
      Gitlab::DataBuilder::Push.sample_data
    end

    def repository_update_events_data
      Gitlab::DataBuilder::Repository.sample_data
    end

    def merge_requests_events_data
      merge_request = MergeRequest.of_projects(current_user.projects.select(:id)).first
      throw(:validation_error, 'Ensure one of your projects has merge requests.') unless merge_request.present?

      merge_request.to_hook_data(current_user)
    end
  end
end
