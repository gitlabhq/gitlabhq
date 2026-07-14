# frozen_string_literal: true

require_relative '../reply_key'
require_relative '../identification'

module Gitlab
  module EmailHandler
    module Matchers
      # Base class for handler matchers. Each matcher mirrors exactly one email
      # handler's mail key parsing and the database-free portion of its
      # `can_handle?` logic. Matchers never touch the database or the network.
      class Base
        # @param mail_key [String]
        # @return [Gitlab::EmailHandler::Identification, nil]
        def match(mail_key)
          raise NotImplementedError
        end

        # The handler name this matcher corresponds to (e.g. :create_issue).
        # @return [Symbol]
        def handler_name
          raise NotImplementedError
        end

        private

        def identification(**attributes)
          Identification.new(handler: handler_name, attributes: attributes)
        end
      end
    end
  end
end
