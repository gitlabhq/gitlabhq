# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          EnvironmentCreationFailure = Class.new(StandardError)

          delegate :dig, to: :@seed_attributes

          def initialize(pipeline, attributes, previous_stages)
            @pipeline = pipeline
            @seed_attributes = attributes
            @previous_stages = previous_stages
            @needs_attributes = dig(:needs_attributes)
            @resource_group_key = attributes.delete(:resource_group_key)

            @using_rules  = attributes.key?(:rules)
            @using_only   = attributes.key?(:only)
            @using_except = attributes.key?(:except)

            @only = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:only))
            @except = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:except))
            @rules = Gitlab::Ci::Build::Rules
              .new(attributes.delete(:rules), default_when: 'on_success')
            @cache = Seed::Build::Cache
              .new(pipeline, attributes.delete(:cache))
          end

          def name
            dig(:name)
          end

          def included?
            strong_memoize(:inclusion) do
              if @using_rules
                rules_result.pass?
              elsif @using_only || @using_except
                all_of_only? && none_of_except?
              else
                true
              end
            end
          end

          def errors
            return unless included?

            strong_memoize(:errors) do
              needs_errors
            end
          end

          def attributes
            @seed_attributes
              .deep_merge(pipeline_attributes)
              .deep_merge(rules_attributes)
              .deep_merge(cache_attributes)
          end

          def bridge?
            attributes_hash = @seed_attributes.to_h
            attributes_hash.dig(:options, :trigger).present? ||
              (attributes_hash.dig(:options, :bridge_needs).instance_of?(Hash) &&
               attributes_hash.dig(:options, :bridge_needs, :pipeline).present?)
          end

          def to_resource
            strong_memoize(:resource) do
              if bridge?
                ::Ci::Bridge.new(attributes)
              else
                ::Ci::Build.new(attributes).tap do |build|
                  build.assign_attributes(self.class.environment_attributes_for(build))
                  build.resource_group = Seed::Build::ResourceGroup.new(build, @resource_group_key).to_resource
                end
              end
            end
          end

          def self.environment_attributes_for(build)
            return {} unless build.has_environment?

            environment = Seed::Environment.new(build).to_resource

            # If there is a validation error on environment creation, such as
            # the name contains invalid character, the build falls back to a
            # non-environment job.
            unless environment.persisted?
              Gitlab::ErrorTracking.track_exception(
                EnvironmentCreationFailure.new,
                project_id: build.project_id,
                reason: environment.errors.full_messages.to_sentence)

              return { environment: nil }
            end

            {
              deployment: Seed::Deployment.new(build, environment).to_resource,
              metadata_attributes: {
                expanded_environment_name: environment.name
              }
            }
          end

          private

          def all_of_only?
            @only.all? { |spec| spec.satisfied_by?(@pipeline, evaluate_context) }
          end

          def none_of_except?
            @except.none? { |spec| spec.satisfied_by?(@pipeline, evaluate_context) }
          end

          def needs_errors
            return if @needs_attributes.nil?

            if @needs_attributes.size > max_needs_allowed
              return [
                "#{name}: one job can only need #{max_needs_allowed} others, but you have listed #{@needs_attributes.size}. " \
                  "See needs keyword documentation for more details"
              ]
            end

            @needs_attributes.flat_map do |need|
              result = @previous_stages.any? do |stage|
                stage.seeds_names.include?(need[:name])
              end

              "#{name}: needs '#{need[:name]}'" unless result
            end.compact
          end

          def max_needs_allowed
            @pipeline.project.actual_limits.ci_needs_size_limit
          end

          def pipeline_attributes
            {
              pipeline: @pipeline,
              project: @pipeline.project,
              user: @pipeline.user,
              ref: @pipeline.ref,
              tag: @pipeline.tag,
              trigger_request: @pipeline.legacy_trigger,
              protected: @pipeline.protected_ref?
            }
          end

          def rules_attributes
            return {} unless @using_rules

            rules_result.build_attributes
          end

          def rules_result
            strong_memoize(:rules_result) do
              @rules.evaluate(@pipeline, evaluate_context)
            end
          end

          def evaluate_context
            strong_memoize(:evaluate_context) do
              Gitlab::Ci::Build::Context::Build.new(@pipeline, @seed_attributes)
            end
          end

          def cache_attributes
            strong_memoize(:cache_attributes) do
              @cache.build_attributes
            end
          end
        end
      end
    end
  end
end
