# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- tracer state must survive between trace hooks
      module IntroducedTracer
        def initialize(...)
          @introduced_tracer_data = {}.compare_by_identity

          super
        end

        def parse(query_string:)
          original_document = super

          filter = Gitlab::Graphql::VersionFilter::FutureFieldFilter.new(original_document.dup)
          filtered_document = filter.visit

          return original_document unless filter.contain_future_fields

          @introduced_tracer_data[filtered_document] = {
            original_document: original_document,
            filter: filter
          }

          filtered_document
        end

        def validate(query:, validate:)
          result = super
          doc_data = @introduced_tracer_data[query.document]

          return result unless doc_data

          result[:errors] = result[:errors]&.reject { |error| doc_data[:filter].suppress?(error) }

          result
        end

        # Restore before analysis, not only before execution, so tagged nodes
        # count toward complexity and depth limits.
        def analyze_query(query:)
          restore_original_document(query)

          super
        end

        def execute_query(query:)
          restore_original_document(query)

          super
        end

        private

        def restore_original_document(query)
          doc_data = @introduced_tracer_data[query.document]

          return unless doc_data

          # Use the original query from here on so we can fallback to null for the missing fields.
          # prepare_ast resets the validation pipeline; keep the already-validated one so the
          # interpreter doesn't re-validate the restored document.
          validation_pipeline = query.instance_variable_get(:@validation_pipeline)
          query.instance_variable_set(:@document, doc_data[:original_document])
          query.send(:prepare_ast) # rubocop:disable GitlabSecurity/PublicSend -- we need to call private method
          query.instance_variable_set(:@validation_pipeline, validation_pipeline)
          query.context[:future_field_names] = doc_data[:filter].future_field_names
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
