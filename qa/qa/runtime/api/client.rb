# frozen_string_literal: true

module QA
  module Runtime
    module API
      class Client
        attr_reader :address, :personal_access_token

        # TODO: remove this method as currently it only serves as a delegator to User::Store
        def self.as_admin
          User::Store.admin_api_client
        end

        def initialize(address = :gitlab, personal_access_token:)
          @address = address
          @personal_access_token = personal_access_token
        end
      end
    end
  end
end
