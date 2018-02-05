module EE
  module API
    module APIGuard
      module HelperMethods
        extend ::Gitlab::Utils::Override

        override :find_user_from_sources
        def find_user_from_sources
          find_user_from_access_token ||
            find_user_from_job_token ||
            find_user_from_warden
        end
      end
    end
  end
end
