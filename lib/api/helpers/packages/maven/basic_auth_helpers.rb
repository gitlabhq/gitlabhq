# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Maven
        module BasicAuthHelpers
          include ::API::Helpers::Packages::BasicAuthHelpers
          extend ::Gitlab::Utils::Override

          # override so that we can receive the job token either by headers or
          # basic auth.
          override :find_user_from_job_token
          def find_user_from_job_token
            super || find_user_from_job_token_basic_auth
          end
        end
      end
    end
  end
end
