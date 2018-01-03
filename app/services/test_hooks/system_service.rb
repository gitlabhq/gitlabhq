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
  end
end
