# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      ThirdPartyValidationError = Class.new(StandardError)

      module Mixins
        # Mixin for classes that inherit from Service::DockerRun::Base
        #
        # Helper for authenticating against private repositories.
        # registry.gitlab.com/gitlab-org/quality/third-party-docker-images
        module ThirdPartyDocker
          # @return [Void]
          def authenticate_third_party(force: false)
            raise_validation_error unless can_authenticate_third_party?

            login(
              third_party_registry,
              user: third_party_registry_user,
              password: third_party_registry_password,
              force: force
            )
          end

          def third_party_registry
            Runtime::Env.third_party_docker_registry
          end

          def third_party_repository
            Runtime::Env.third_party_docker_repository
          end

          def third_party_registry_user
            Runtime::Env.third_party_docker_user
          end

          def third_party_registry_password
            Runtime::Env.third_party_docker_password
          end

          private

          def raise_validation_error
            raise ThirdPartyValidationError, 'Third party docker environment variable(s) are not set'
          end

          def can_authenticate_third_party?
            [
              :third_party_registry,
              :third_party_registry_user,
              :third_party_registry_password
            ].all? { |method| send(method).present? }
          end
        end
      end
    end
  end
end
