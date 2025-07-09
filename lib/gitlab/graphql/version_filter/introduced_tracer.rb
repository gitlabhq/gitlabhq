# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- we need to keep the original query for the fallback later
      module IntroducedTracer
        def parse(query_string:)
          @original_query_document = super
          @contain_future_fields = false

          filter = Gitlab::Graphql::VersionFilter::FutureFieldFilter.new(@original_query_document.dup)

          filter.visit.tap do
            @contain_future_fields = filter.contain_future_fields
          end
        end

        def execute_query(query:)
          return super unless @contain_future_fields

          # Use the original query during execution so we can fallback to null for the missing fields
          query.instance_variable_set(:@document, @original_query_document)
          query.send(:prepare_ast) # rubocop:disable GitlabSecurity/PublicSend -- we need to call private method
          query.context[:contain_future_fields] = @contain_future_fields

          super
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
