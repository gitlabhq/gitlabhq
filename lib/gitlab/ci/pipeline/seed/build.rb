# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :dig, to: :@seed_attributes

          def initialize(context, attributes, stages_for_needs_lookup = [])
            @context = context
            @pipeline = context.pipeline
            @seed_attributes = attributes
            @stages_for_needs_lookup = stages_for_needs_lookup.compact
            @needs_attributes = dig(:needs_attributes)
            @resource_group_key = attributes.delete(:resource_group_key)
            @job_variables = @seed_attributes.delete(:job_variables)
            @root_variables_inheritance = @seed_attributes.delete(:root_variables_inheritance) { true }

            @using_rules  = attributes.key?(:rules)
            @using_only   = attributes.key?(:only)
            @using_except = attributes.key?(:except)

            @only = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:only))
            @except = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:except))
            @rules = Gitlab::Ci::Build::Rules
              .new(attributes.delete(:rules), default_when: attributes[:when])
            @cache = Gitlab::Ci::Build::Cache
              .new(attributes.delete(:cache), @pipeline)

            calculate_yaml_variables!
          end

          def name
            dig(:name)
          end

          def included?
            strong_memoize(:inclusion) do
              logger.instrument(:pipeline_seed_build_inclusion) do
                if @using_rules
                  rules_result.pass?
                elsif @using_only || @using_except
                  all_of_only? && none_of_except?
                else
                  true
                end
              end
            end
          end

          def errors
            strong_memoize(:errors) do
              # We check rules errors before checking "included?" because rules affects its inclusion status.
              next rules_errors if rules_errors
              next unless included?

              [needs_errors, variable_expansion_errors].compact.flatten
            end
          end

          def attributes
            @seed_attributes
              .deep_merge(pipeline_attributes)
              .deep_merge(rules_attributes)
              .deep_merge(allow_failure_criteria_attributes)
              .deep_merge(@cache.cache_attributes)
              .deep_merge(runner_tags)
          end

          def bridge?
            attributes_hash = @seed_attributes.to_h
            attributes_hash.dig(:options, :trigger).present? ||
              (attributes_hash.dig(:options, :bridge_needs).instance_of?(Hash) &&
               attributes_hash.dig(:options, :bridge_needs, :pipeline).present?)
          end

          def to_resource
            strong_memoize(:resource) do
              initialize_processable
            end
          end

          def initialize_processable
            if bridge?
              ::Ci::Bridge.new(attributes)
            else
              ::Ci::Build.new(attributes)
            end
          end

          private

          delegate :logger, to: :@context

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
              next if need[:optional]

              result = need_present?(need)

              "'#{name}' job needs '#{need[:name]}' job, but '#{need[:name]}' is not in any previous stage" unless result
            end.compact
          end

          def need_present?(need)
            @stages_for_needs_lookup.any? do |stage|
              stage.seeds_names.include?(need[:name])
            end
          end

          def max_needs_allowed
            @pipeline.project.actual_limits.ci_needs_size_limit
          end

          def variable_expansion_errors
            expanded_collection = evaluate_context.variables.sort_and_expand_all
            errors = expanded_collection.errors
            ["#{name}: #{errors}"] if errors
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
            strong_memoize(:rules_attributes) do
              next {} unless @using_rules

              rules_variables_result = ::Gitlab::Ci::Variables::Helpers.merge_variables(
                @seed_attributes[:yaml_variables], rules_result.variables
              )

              rules_result.build_attributes.merge(yaml_variables: rules_variables_result)
            end
          end

          def rules_result
            strong_memoize(:rules_result) do
              @rules.evaluate(@pipeline, evaluate_context)
            end
          end

          def rules_errors
            strong_memoize(:rules_errors) do
              ["Failed to parse rule for #{name}: #{rules_result.errors.join(', ')}"] if rules_result.errors.present?
            end
          end

          def evaluate_context
            strong_memoize(:evaluate_context) do
              Gitlab::Ci::Build::Context::Build.new(@pipeline, @seed_attributes)
            end
          end

          def runner_tags
            strong_memoize(:runner_tags) do
              { tag_list: evaluate_runner_tags }.compact
            end
          end

          def evaluate_runner_tags
            @seed_attributes.delete(:tag_list)&.map do |tag|
              ExpandVariables.expand_existing(tag, -> { evaluate_context.variables_hash })
            end
          end

          # If a job uses `allow_failure:exit_codes` and `rules:allow_failure`
          # we need to prevent the exit codes from being persisted because they
          # would break the behavior defined by `rules:allow_failure`.
          def allow_failure_criteria_attributes
            return {} if rules_attributes[:allow_failure].nil?
            return {} unless @seed_attributes.dig(:options, :allow_failure_criteria)

            { options: { allow_failure_criteria: nil } }
          end

          def calculate_yaml_variables!
            @seed_attributes[:yaml_variables] = Gitlab::Ci::Variables::Helpers.inherit_yaml_variables(
              from: @context.root_variables, to: @job_variables, inheritance: @root_variables_inheritance
            )
          end
        end
      end
    end
  end
end
