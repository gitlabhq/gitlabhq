# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- we need to keep the original query for the fallback later
      module IntroducedTracer
        def initialize(...)
          @introduced_tracer_data = {}

          super
        end

        def parse(query_string:)
          original_document = super

          filter = Gitlab::Graphql::VersionFilter::FutureFieldFilter.new(original_document.dup)
          filtered_document = filter.visit

          @introduced_tracer_data[filtered_document] = {
            original_document: original_document,
            contain_future_fields: filter.contain_future_fields
          }

          filtered_document
        end

        def execute_query(query:)
          doc_data = @introduced_tracer_data[query.document]

          if doc_data && doc_data[:contain_future_fields]
            # Use the original query during execution so we can fallback to null for the missing fields
            query.instance_variable_set(:@document, doc_data[:original_document])
            query.send(:prepare_ast) # rubocop:disable GitlabSecurity/PublicSend -- we need to call private method
            query.context[:contain_future_fields] = doc_data[:contain_future_fields]
          end

          super
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
