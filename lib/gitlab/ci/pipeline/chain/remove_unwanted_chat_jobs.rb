# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class RemoveUnwantedChatJobs < Chain::Base
          def perform!
            raise ArgumentError, 'missing config processor' unless @command.config_processor

            return unless pipeline.chat?

            # When scheduling a chat pipeline we only want to run the build
            # that matches the chat command.
            @command.config_processor.jobs.select! do |name, _|
              name.to_s == command.chat_data[:command].to_s
            end
          end

          def break?
            false
          end
        end
      end
    end
  end
end
