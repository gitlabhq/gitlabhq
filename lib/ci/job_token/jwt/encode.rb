# frozen_string_literal: true

module Ci
  module JobToken
    module Jwt
      class Encode < Gitlab::Authz::Token::Encode
        extend ::Ci::JobToken::Jwt::Token

        # After finishing, jobs need to be able to POST their final state to the `jobs` API endpoint,
        # for example to update their status or the final trace.
        # A leeway of 5 minutes ensures a job is able to do that after they have timed out.
        LEEWAY = 5.minutes

        def initialize(job)
          @job = job

          super
        end

        def jwt
          return unless job.persisted?

          token = encode(expire_time: expire_time)
          prefix_token(token)
        end

        private

        attr_reader :job

        def expire_time
          timeout = [JSONWebToken::Token::DEFAULT_EXPIRE_TIME, job.metadata_timeout.to_i].max
          Time.current + timeout + LEEWAY
        end

        def prefix_token(token)
          return unless token

          self.class.token_prefix + token
        end
      end
    end
  end
end
