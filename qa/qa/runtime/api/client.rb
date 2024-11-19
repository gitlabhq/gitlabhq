# frozen_string_literal: true

module QA
  module Runtime
    module API
      class Client
        attr_reader :address

        # TODO: remove this method as currently it only serves as a delegator to UserStore
        def self.as_admin
          UserStore.admin_api_client
        end

        def initialize(address = :gitlab, personal_access_token: nil, user: nil)
          @user = user
          @address = address
          # TODO: remove ability to pass user to completely decouple client from all UI operations
          @personal_access_token = if personal_access_token
                                     personal_access_token
                                   elsif user.nil?
                                     Env.personal_access_token || Env.admin_personal_access_token
                                   end

          return unless user.nil? && @personal_access_token.nil?

          raise ArgumentError, "either user or personal_access_token must be provided"
        end

        # Personal access token
        #
        # @return [String]
        def personal_access_token
          @personal_access_token ||= user.personal_access_token&.token || user.create_personal_access_token!.token
        end

        private

        attr_reader :user
      end
    end
  end
end
