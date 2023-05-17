# frozen_string_literal: true

module API
  class Integrations
    module Slack
      module Concerns
        module VerifiesRequest
          extend ActiveSupport::Concern

          included do
            before { verify_slack_request! }

            helpers do
              def verify_slack_request!
                unauthorized! unless Request.verify!(request)
              end
            end
          end
        end
      end
    end
  end
end
