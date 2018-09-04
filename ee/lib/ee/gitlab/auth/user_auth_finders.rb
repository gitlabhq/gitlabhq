module EE
  module Gitlab
    module Auth
      module UserAuthFinders
        extend ActiveSupport::Concern

        JOB_TOKEN_HEADER = "HTTP_JOB_TOKEN".freeze
        JOB_TOKEN_PARAM = :job_token

        # rubocop: disable CodeReuse/ActiveRecord
        def find_user_from_job_token
          return unless route_authentication_setting[:job_token_allowed]

          token = (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER]).to_s
          return unless token.present?

          job = ::Ci::Build.find_by(token: token)
          raise ::Gitlab::Auth::UnauthorizedError unless job

          @job_token_authentication = true # rubocop:disable Gitlab/ModuleWithInstanceVariables

          job.user
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
