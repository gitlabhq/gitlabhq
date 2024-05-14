# frozen_string_literal: true

module Gitlab
  module Email
    module Handler
      class BaseHandler
        attr_reader :mail, :mail_key

        HANDLER_ACTION_BASE_REGEX = /(?<project_slug>.+)-(?<project_id>\d+)/

        def initialize(mail, mail_key)
          @mail = mail
          @mail_key = mail_key
        end

        def can_handle?
          raise NotImplementedError
        end

        def execute
          raise NotImplementedError
        end

        def metrics_params
          { handler: self.class.name }
        end

        # Each handler should use it's own metric event.  Otherwise there
        # is a possibility that within the same Sidekiq process, that same
        # event with different metrics_params will cause Prometheus to
        # throw an error
        def metrics_event
          raise NotImplementedError
        end
      end
    end
  end
end
