# frozen_string_literal: true

module Gitlab
  module Email
    module Handler
      class BaseHandler
        attr_reader :mail, :mail_key

        HANDLER_ACTION_BASE_REGEX ||= /(?<project_slug>.+)-(?<project_id>\d+)/.freeze

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
      end
    end
  end
end
