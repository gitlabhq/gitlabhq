# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :dig, to: :@attributes

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
            return unless Feature.enabled?(:ci_dag_support, @pipeline.project)
            return if @needs_attributes.nil?

            @needs_attributes.flat_map do |need|
              result = @previous_stages.any? do |stage|
                stage.seeds_names.include?(need[:name])
              end

              "#{name}: needs '#{need[:name]}'" unless result
            end.compact
          end
        end
      end
    end
  end
end
