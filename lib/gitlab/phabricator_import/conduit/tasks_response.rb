# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      class TasksResponse
        def initialize(conduit_response)
          @conduit_response = conduit_response
        end

        delegate :pagination, to: :conduit_response

        def tasks
          @tasks ||= conduit_response.data.map do |task_json|
            Gitlab::PhabricatorImport::Representation::Task.new(task_json)
          end
        end

        private

        attr_reader :conduit_response
      end
    end
  end
end
