# frozen_string_literal: true

class ChatNotificationWorker
  include ApplicationWorker

  RESCHEDULE_INTERVAL = 2.seconds

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      send_response(build)
    end
  rescue Gitlab::Chat::Output::MissingBuildSectionError
    # The creation of traces and sections appears to be eventually consistent.
    # As a result it's possible for us to run the above code before the trace
    # sections are present. To better handle such cases we'll just reschedule
    # the job instead of producing an error.
    self.class.perform_in(RESCHEDULE_INTERVAL, build_id)
  end

  def send_response(build)
    Gitlab::Chat::Responder.responder_for(build).try do |responder|
      if build.success?
        output = Gitlab::Chat::Output.new(build)

        responder.success(output.to_s)
      else
        responder.failure
      end
    end
  end
end
