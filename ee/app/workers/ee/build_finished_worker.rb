module EE
  module BuildFinishedWorker
    def perform(build_id)
      super

      ::Ci::Build.find_by(id: build_id).try do |build|
        ChatNotificationWorker.perform_async(build_id) if build.pipeline.chat?
      end
    end
  end
end
