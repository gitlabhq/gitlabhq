# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Context
        class Build < Base
          include Gitlab::Utils::StrongMemoize

          attr_reader :attributes

          def initialize(pipeline, attributes = {})
            super(pipeline)

            @attributes = attributes
          end

          def variables
            if Feature.enabled?(:ci_variables_optimization_for_yaml_and_node, project)
              pipeline
                .variables_builder
                .scoped_variables_for_pipeline_seed(
                  attributes,
                  user: pipeline.user,
                  trigger_request: pipeline.legacy_trigger,
                  environment: seed_environment,
                  kubernetes_namespace: seed_kubernetes_namespace
                )
            else
              stub_build.scoped_variables
            end
          end
          strong_memoize_attr :variables

          private

          # Copied from `app/models/concerns/ci/deployable.rb#expanded_environment_name`
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/479126
          def seed_environment
            return unless attributes[:environment].present?

            # The initial `environment` parameter is `expanded_environment_name` for a build.
            # The `expanded_environment_name` method uses `metadata&.expanded_environment_name` first to check
            # but we don't need it here because `metadata.expanded_environment_name` is only set in
            # `app/services/environments/create_for_job_service.rb` which is after the pipeline creation.
            ExpandVariables.expand(attributes[:environment], -> { simple_variables.sort_and_expand_all })
          end

          # Copied from `app/models/concerns/ci/deployable.rb#expanded_kubernetes_namespace`
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/479126
          def seed_kubernetes_namespace
            return unless attributes[:environment].present?

            namespace = attributes[:options]&.dig(:environment, :kubernetes, :namespace)

            return unless namespace.present?

            ExpandVariables.expand(namespace, -> { simple_variables })
          end

          def simple_variables
            pipeline.variables_builder.scoped_variables_for_pipeline_seed(
              attributes,
              environment: nil, kubernetes_namespace: nil, user: pipeline.user, trigger_request: pipeline.legacy_trigger
            )
          end
          strong_memoize_attr :simple_variables

          def stub_build
            # This is a temporary piece of technical debt to allow us access
            # to the CI variables to evaluate rules before we persist a Build
            # with the result. We should refactor away the extra Build.new,
            # but be able to get CI Variables directly from the Seed::Build.
            ::Ci::Build.new(build_attributes)
          end

          # Assigning tags and needs is slow and they are not needed for rules
          # evaluation since we don't use them to compute the variables at this point.
          def build_attributes
            attributes
              .except(:tag_list, :needs_attributes)
              .merge!(pipeline_attributes, ci_stage_attributes)
          end

          def ci_stage_attributes
            {
              ci_stage: ::Ci::Stage.new(
                name: attributes[:stage],
                position: attributes[:stage_idx],
                pipeline: pipeline_attributes[:pipeline],
                project: pipeline_attributes[:project]
              )
            }
          end
        end
      end
    end
  end
end
