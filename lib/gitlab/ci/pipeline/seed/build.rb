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
                none_of_except? &&
                all_of_needs?
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

          def all_of_only?
            @only.all? { |spec| spec.satisfied_by?(@pipeline, self) }
          end

          def none_of_except?
            @except.none? { |spec| spec.satisfied_by?(@pipeline, self) }
          end

          def all_of_needs?
            return true unless Feature.enabled?(:ci_dag_support, @pipeline.project)
            return true if dig(:needs_attributes).nil?

            dig(:needs_attributes).all? do |need|
              @previous_stages.any? do |stage|
                stage.seeds_names.include?(need[:name])
              end
            end
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
        end
      end
    end
  end
end
