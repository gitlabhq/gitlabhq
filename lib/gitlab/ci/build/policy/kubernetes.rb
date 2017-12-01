module Gitlab
  module Ci
    module Build
      module Policy
        class Kubernetes < Policy::Specification
          def initialize(spec)
            unless spec.to_sym == :active
              raise UnknownPolicyError
            end
          end

          ##
          # TODO:
          # KubernetesService is being replaced by Platform::Kubernetes.
          # The new Platform::Kubernetes belongs to multiple environments in a project,
          # which means we should do `project.deployment_platform(environment: job.environment)&.active?`
          # to check the activeness of the corresponded Kubernetes instance.
          # Currently, `kubernetes: active` keyword is defined as it takes an effect on project-wide,
          # At some points, it also makes sense, therefore we need to figure out a better shape.
          def satisfied_by?(pipeline)
            pipeline.has_kubernetes_active?
          end
        end
      end
    end
  end
end
