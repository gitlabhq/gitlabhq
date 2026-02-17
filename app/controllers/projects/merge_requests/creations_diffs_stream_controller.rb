# frozen_string_literal: true

module Projects
  module MergeRequests
    class CreationsDiffsStreamController < Projects::MergeRequests::CreationsController
      include RapidDiffs::StreamingResource
    end
  end
end
