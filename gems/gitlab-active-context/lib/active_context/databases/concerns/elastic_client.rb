# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module ElasticClient
        include ActiveContext::Databases::Concerns::Client

        def add_source_fields(query, source_fields)
          return query unless source_fields

          query.merge(_source: { includes: source_fields })
        end
      end
    end
  end
end
