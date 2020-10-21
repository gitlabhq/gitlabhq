# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module Strategies
        class Base
          def initialize(user)
            @user = user
          end

          private

          attr_reader :user

          def success
            { status: :success }
          end

          def error(message, http_status = nil)
            result = { message: message,
                       status: :error }

            result[:http_status] = http_status if http_status

            result
          end
        end
      end
    end
  end
end
