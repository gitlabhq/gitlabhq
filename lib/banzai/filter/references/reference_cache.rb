# frozen_string_literal: true

module Banzai
  module Filter
    module References
      class ReferenceCache
        include Gitlab::Utils::StrongMemoize
        include RequestStoreReferenceCache

        def initialize(filter, context)
          @filter = filter
          @context = context
        end

        def load_reference_cache(nodes)
          load_references_per_parent(nodes)
          load_parent_per_reference
          load_records_per_parent

          @cache_loaded = true
        end

        # Loads all object references (e.g. issue IDs) per
        # project/group they belong to.
        def load_references_per_parent(nodes)
          @references_per_parent ||= {}

          @references_per_parent[parent_type] ||= begin
            refs = Hash.new { |hash, key| hash[key] = Set.new }

            nodes.each do |node|
              prepare_node_for_scan(node).scan(regex) do
                parent_path = if parent_type == :project
                                full_project_path($~[:namespace], $~[:project])
                              else
                                full_group_path($~[:group])
                              end

                ident = filter.identifier($~)
                refs[parent_path] << ident if ident
              end
            end

            refs
          end
        end

        def references_per_parent
          @references_per_parent[parent_type]
        end

        # Returns a Hash containing referenced projects grouped per their full
        # path.
        def load_parent_per_reference
          @per_reference ||= {}

          @per_reference[parent_type] ||= begin
            refs = references_per_parent.keys
            parent_ref = {}

            # if we already have a parent, no need to query it again
            refs.each do |ref|
              next unless ref

              if context[:project]&.full_path == ref
                parent_ref[ref] = context[:project]
              elsif context[:group]&.full_path == ref
                parent_ref[ref] = context[:group]
              end

              refs -= [ref] if parent_ref[ref]
            end

            find_for_paths(refs).index_by(&:full_path).merge(parent_ref)
          end
        end

        def parent_per_reference
          @per_reference[parent_type]
        end

        def load_records_per_parent
          @_records_per_project ||= {}

          @_records_per_project[filter.object_class.to_s.underscore] ||= begin
            hash = Hash.new { |h, k| h[k] = {} }

            parent_per_reference.each do |path, parent|
              record_ids = references_per_parent[path]

              filter.parent_records(parent, record_ids).each do |record|
                hash[parent][filter.record_identifier(record)] = record
              end
            end

            hash
          end
        end

        def records_per_parent
          @_records_per_project[filter.object_class.to_s.underscore]
        end

        def objects_for_paths(paths)
          klass = parent_type.to_s.camelize.constantize
          result = klass.where_full_path_in(paths)
          return result if parent_type == :group

          result.includes(namespace: :route) if parent_type == :project
        end

        # Returns projects for the given paths.
        def find_for_paths(paths)
          if Gitlab::SafeRequestStore.active?
            cache = refs_cache
            to_query = paths - cache.keys

            unless to_query.empty?
              records = objects_for_paths(to_query)

              found = []
              records.each do |record|
                ref = record.full_path
                get_or_set_cache(cache, ref) { record }
                found << ref
              end

              not_found = to_query - found
              not_found.each do |ref|
                get_or_set_cache(cache, ref) { nil }
              end
            end

            cache.slice(*paths).values.compact
          else
            objects_for_paths(paths)
          end
        end

        def current_parent_path
          strong_memoize(:current_parent_path) do
            parent&.full_path
          end
        end

        def current_project_namespace_path
          strong_memoize(:current_project_namespace_path) do
            project&.namespace&.full_path
          end
        end

        def full_project_path(namespace, project_ref)
          return current_parent_path unless project_ref

          namespace_ref = namespace || current_project_namespace_path
          "#{namespace_ref}/#{project_ref}"
        end

        def full_group_path(group_ref)
          return current_parent_path unless group_ref

          group_ref
        end

        def cache_loaded?
          !!@cache_loaded
        end

        private

        attr_accessor :filter, :context

        delegate :project, :group, :parent, :parent_type, to: :filter

        def regex
          strong_memoize(:regex) do
            [
              filter.object_class.link_reference_pattern,
              filter.object_class.reference_pattern
            ].compact.reduce { |a, b| Regexp.union(a, b) }
          end
        end

        def refs_cache
          Gitlab::SafeRequestStore["banzai_#{parent_type}_refs".to_sym] ||= {}
        end

        def prepare_node_for_scan(node)
          html = node.to_html

          filter.requires_unescaping? ? unescape_html_entities(html) : html
        end

        def unescape_html_entities(text)
          CGI.unescapeHTML(text.to_s)
        end
      end
    end
  end
end

Banzai::Filter::References::ReferenceCache.prepend_mod
