module EE
  module BuildFinishedWorker
    # rubocop: disable CodeReuse/ActiveRecord
    def perform(build_id)
      super

      ::Ci::Build.find_by(id: build_id).try do |build|
        ChatNotificationWorker.perform_async(build_id) if build.pipeline.chat?
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
