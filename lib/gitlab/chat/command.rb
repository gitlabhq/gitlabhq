# frozen_string_literal: true

module Gitlab
  module Chat
    # Class for scheduling chat pipelines.
    #
    # A Command takes care of creating a `Ci::Pipeline` with all the data
    # necessary to execute a chat command. This includes data such as the chat
    # data (e.g. the response URL) and any environment variables that should be
    # exposed to the chat command.
    class Command
      include Utils::StrongMemoize

      attr_reader :project, :chat_name, :name, :arguments, :response_url,
                  :channel

      # project - The Project to schedule the command for.
      # chat_name - The ChatName belonging to the user that scheduled the
      #             command.
      # name - The name of the chat command to run.
      # arguments - The arguments (as a String) to pass to the command.
      # channel - The channel the message was sent from.
      # response_url - The URL to send the response back to.
      def initialize(project:, chat_name:, name:, arguments:, channel:, response_url:)
        @project = project
        @chat_name = chat_name
        @name = name
        @arguments = arguments
        @channel = channel
        @response_url = response_url
      end

      # Tries to create a new pipeline.
      #
      # This method will return a pipeline that _may_ be persisted, or `nil` if
      # the pipeline could not be created.
      def try_create_pipeline
        return unless valid?

        create_pipeline
      end

      def create_pipeline
        service = ::Ci::CreatePipelineService.new(
          project,
          chat_name.user,
          ref: branch,
          sha: commit,
          chat_data: {
            chat_name_id: chat_name.id,
            command: name,
            arguments: arguments,
            response_url: response_url
          }
        )

        service.execute(:chat) do |pipeline|
          build_environment_variables(pipeline)
          build_chat_data(pipeline)
        end
      end

      # pipeline - The `Ci::Pipeline` to create the environment variables for.
      def build_environment_variables(pipeline)
        pipeline.variables.build(
          [{ key: 'CHAT_INPUT', value: arguments },
           { key: 'CHAT_CHANNEL', value: channel }]
        )
      end

      # pipeline - The `Ci::Pipeline` to create the chat data for.
      def build_chat_data(pipeline)
        pipeline.build_chat_data(
          chat_name_id: chat_name.id,
          response_url: response_url
        )
      end

      def valid?
        branch && commit
      end

      def branch
        strong_memoize(:branch) { project.default_branch }
      end

      def commit
        strong_memoize(:commit) do
          project.commit(branch)&.id if branch
        end
      end
    end
  end
end
