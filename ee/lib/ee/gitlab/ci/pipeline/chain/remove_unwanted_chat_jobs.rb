module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          class RemoveUnwantedChatJobs < ::Gitlab::Ci::Pipeline::Chain::Base
            def perform!
              return unless pipeline.config_processor && pipeline.chat?

              # When scheduling a chat pipeline we only want to run the build
              # that matches the chat command.
              pipeline.config_processor.jobs.select! do |name, _|
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
end
