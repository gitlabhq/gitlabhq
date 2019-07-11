# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    module Conduit
      class UsersResponse
        def initialize(conduit_response)
          @conduit_response = conduit_response
        end

        def users
          @users ||= conduit_response.data.map do |user_json|
            Gitlab::PhabricatorImport::Representation::User.new(user_json)
          end
        end

        private

        attr_reader :conduit_response
      end
    end
  end
end
