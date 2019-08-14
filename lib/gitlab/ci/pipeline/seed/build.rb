# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :dig, to: :@attributes

          # When the `ci_dag_limit_needs` is enabled it uses the lower limit
          LOW_NEEDS_LIMIT = 5
          HARD_NEEDS_LIMIT = 50

          def initialize(pipeline, attributes, previous_stages)
            @pipeline = pipeline
            @attributes = attributes
            @previous_stages = previous_stages
            @needs_attributes = dig(:needs_attributes)

            @only = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:only))
            @except = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:except))
          end

          def name
            dig(:name)
          end

          def included?
            strong_memoize(:inclusion) do
              all_of_only? &&
                none_of_except?
            end
          end

          def errors
            return unless included?

            strong_memoize(:errors) do
              needs_errors
            end
          end

          def attributes
            @attributes.merge(
              pipeline: @pipeline,
              project: @pipeline.project,
              user: @pipeline.user,
              ref: @pipeline.ref,
              tag: @pipeline.tag,
              trigger_request: @pipeline.legacy_trigger,
              protected: @pipeline.protected_ref?
            )
          end

          def bridge?
            @attributes.to_h.dig(:options, :trigger).present?
          end

          def to_resource
            strong_memoize(:resource) do
              if bridge?
                ::Ci::Bridge.new(attributes)
              else
                ::Ci::Build.new(attributes)
              end
            end
          end

          private

          def all_of_only?
            @only.all? { |spec| spec.satisfied_by?(@pipeline, self) }
          end

          def none_of_except?
            @except.none? { |spec| spec.satisfied_by?(@pipeline, self) }
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
            if Feature.enabled?(:ci_dag_limit_needs, @project, default_enabled: true)
              LOW_NEEDS_LIMIT
            else
              HARD_NEEDS_LIMIT
            end
          end
        end
      end
    end
  end
end
