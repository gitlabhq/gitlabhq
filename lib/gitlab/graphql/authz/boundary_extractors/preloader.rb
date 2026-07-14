# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module BoundaryExtractors
        class Preloader
          GRANULAR_TOKENS_BOUNDARY_CACHE_KEY = :granular_tokens_boundary_cache

          class << self
            # Collects all the granular token directives and nodes to preload the boundaries
            def preload_boundaries(type, nodes, context)
              token = context[:access_token]
              return unless token && token.respond_to?(:granular?)

              nodes = nodes.compact
              return if nodes.empty?

              directives = granular_directives(type, nodes, context)
              return if directives.empty?

              new(directives).preload_all(nodes, token)
            end

            def granular_directives(type, nodes, context)
              granular_auth = type.try(:granular_scope_authorization)
              return granular_auth.directives if granular_auth&.any?

              return [] unless type.respond_to?(:resolve_type)

              # in case the nodes are of type BaseInterface,
              # use the directives defined in their resolve_type
              nodes
                .uniq(&:class)
                .filter_map { |node| type.resolve_type(node, context).try(:granular_scope_authorization) }
                .flat_map(&:directives)
            end
          end

          def initialize(directives)
            @directives = directives
          end

          def preload_all(nodes, token)
            preload_boundary_associations(nodes)
            preload_root_namespace_enforcement(nodes) if token.legacy?
          end

          private

          attr_reader :directives

          # Step 1: for each node, load its boundary record
          # We batch across all nodes to avoid N+1s, and cache the loaded
          # boundary records so they can be reused if the same boundary appears again later
          # in the request (e.g. 100 jobs all pointing at the same project).
          def preload_boundary_associations(nodes)
            nodes.group_by(&:class).each do |klass, records|
              next unless klass.respond_to?(:reflect_on_association)

              boundary_associations = directives
                .filter_map { |directive| boundary_association_for(klass, directive) }
                .uniq

              next if boundary_associations.empty?

              ActiveRecord::Associations::Preloader.new(
                records: records,
                associations: boundary_associations,
                available_records: cache.values
              ).call

              cache_boundary_records(records, boundary_associations)
            end
          end

          # Step 2: for legacy tokens we also need the root namespace of each boundary
          # for enforcement checks.
          def preload_root_namespace_enforcement(nodes)
            root_namespace_ids = nodes
              .flat_map { |node| BoundaryExtractor.new(directives, object: node, arguments: nil).extract }
              .filter_map { |resource| ::Authz::Boundary.for(resource)&.root_namespace_id }

            ::Authz::Tokens::EnforcementCache.new.any_enforced?(root_namespace_ids)
          end

          # Builds the AR association path from a node to its boundary record.
          # For eg. if boundary_type: :project, we always need to load :project_namespace as well
          def boundary_association_for(klass, directive)
            boundary_method = directive.arguments[:boundary]&.to_sym
            return unless boundary_method

            strategy = ::Authz::Boundary.strategy_for_type(directive.arguments[:boundary_type])
            return unless strategy

            namespace_association = strategy.namespace_association

            if boundary_method == BoundaryExtractor::ITSELF
              namespace_association if namespace_association && klass.reflect_on_association(namespace_association)
            else
              reflection = klass.reflect_on_association(boundary_method)
              return unless reflection && !reflection.polymorphic? && reflection.klass <= strategy.record_class

              namespace_association ? { boundary_method => namespace_association } : boundary_method
            end
          end

          # Stores boundary records (projects, namespaces) loaded during this request
          # so that the AR preloader can reuse them via `available_records` instead
          # of issuing duplicate queries for shared boundaries.
          def cache_boundary_records(records, associations)
            associations.each do |association|
              if association.is_a?(Hash)
                association.each do |boundary_association, namespace_association|
                  boundary_records = fetch_preloaded(records, boundary_association)
                  namespace_records = fetch_preloaded(boundary_records, namespace_association)

                  write_to_boundary_record_cache(boundary_records)
                  write_to_boundary_record_cache(namespace_records)
                end
              else
                write_to_boundary_record_cache(fetch_preloaded(records, association))
              end
            end
          end

          def write_to_boundary_record_cache(records)
            records.each { |record| cache[[record.class.name, record.id]] = record }
          end

          def fetch_preloaded(records, association)
            records
            .map { |record| record.association(association) }
            .select(&:loaded?)
            .flat_map(&:target)
            .compact
          end

          def cache
            @cache ||= Gitlab::SafeRequestStore.fetch(GRANULAR_TOKENS_BOUNDARY_CACHE_KEY) { {} }
          end
        end
      end
    end
  end
end
