require 'gitlab/email/handler/ee/service_desk_handler'

module EE
  module Gitlab
    module Email
      module Handler
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :load_handlers
          def load_handlers
            [
              ::Gitlab::Email::Handler::EE::ServiceDeskHandler,
              *super
            ]
          end
        end
      end
    end
  end
end
