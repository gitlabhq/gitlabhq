# frozen_string_literal: true

module Banzai
  module Filter
    module References
      class ReferenceCache
        include Gitlab::Utils::StrongMemoize
        include RequestStoreReferenceCache

        def initialize(filter, context, result)
          @filter = filter
          @context = context
          @result = result || {}
        end

        def load_reference_cache(nodes)
          load_references_per_parent(nodes)
          load_parent_per_reference
          load_records_per_parent

          @cache_loaded = true
        end

        def references_per_parent
          @references_per_parent[parent_type]
        end

        def parent_per_reference
          @per_reference[parent_type]
        end

        def records_per_parent
          @_records_per_project[filter.object_class.to_s.underscore]
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

        def full_project_path(namespace, project_ref, matches = nil)
          return current_parent_path unless project_ref

          matched_absolute_path = matches&.named_captures&.fetch('absolute_path')
          namespace ||= current_project_namespace_path unless matched_absolute_path

          full_path = []
          full_path << '/' if matched_absolute_path
          full_path << "#{namespace}/" if namespace
          full_path << project_ref
          full_path.join
        end

        def full_group_path(group_ref)
          return current_parent_path unless group_ref

          group_ref
        end

        def full_namespace_path(matches)
          return current_parent_path if matches.named_captures['group_or_project_namespace'].blank?

          matches[:group_or_project_namespace]
        end

        def cache_loaded?
          !!@cache_loaded
        end

        private

        attr_accessor :filter, :context, :result

        delegate :project, :group, :parent, :parent_type, to: :filter

        # Loads all object references (e.g. issue IDs) per
        # project/group they belong to.
        def load_references_per_parent(nodes)
          @references_per_parent ||= {}

          @references_per_parent[parent_type] ||= begin
            refs = Hash.new { |hash, key| hash[key] = Set.new }

            [filter.object_class.link_reference_pattern, filter.object_class.reference_pattern].each do |pattern|
              next unless pattern

              prepare_doc_for_scan.to_enum(:scan, pattern).each do
                parent_path = if parent_type == :group
                                full_group_path($~[:group])
                              elsif parent_type == :namespace
                                full_namespace_path($~)
                              else
                                full_project_path($~[:namespace], $~[:project], $~)
                              end

                ident = filter.identifier($~)
                refs[parent_path] << ident if ident
              end
            end

            refs
          end
        end

        # Returns a Hash containing referenced projects grouped per their full
        # path.
        def load_parent_per_reference
          @per_reference ||= {}

          @per_reference[parent_type] ||= begin
            refs = references_per_parent.keys.compact
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

            absolute_paths = refs.filter_map { |ref| ref if ref[0] == '/' }
            relative_paths = refs - absolute_paths

            find_for_paths(relative_paths, false).index_by(&:full_path)
              .merge(find_for_paths(absolute_paths, true).index_by { |object| "/#{object.full_path}" })
              .merge(parent_ref)
          end
        end

        def load_records_per_parent
          @_records_per_project ||= {}

          @_records_per_project[filter.object_class.to_s.underscore] ||= begin
            hash = Hash.new { |h, k| h[k] = {} }

            parent_per_reference.each do |path, parent|
              record_ids = references_per_parent[path]

              filter.parent_records(parent, record_ids)&.each do |record|
                hash[parent][filter.record_identifier(record)] = record
              end
            end

            hash
          end
        end

        # Returns projects for the given paths.
        def find_for_paths(paths, absolute_path = false)
          return [] if paths.empty?

          if Gitlab::SafeRequestStore.active?
            cached_objects_for_paths(paths, absolute_path)
          else
            objects_for_paths(paths, absolute_path)
          end
        end

        def cached_objects_for_paths(paths, absolute_path)
          cache = refs_cache
          to_query = paths - cache.keys

          unless to_query.empty?
            records = objects_for_paths(to_query, absolute_path)

            found = []
            records.each do |record|
              ref = absolute_path ? "/#{record.full_path}" : record.full_path
              get_or_set_cache(cache, ref) { record }
              found << ref
            end

            not_found = to_query - found
            not_found.each do |ref|
              get_or_set_cache(cache, ref) { nil }
            end
          end

          cache.slice(*paths).values.compact
        end

        def objects_for_paths(paths, absolute_path)
          search_paths = absolute_path ? paths.pluck(1..-1) : paths

          Route.by_paths(search_paths).preload(source: [:route, { namespace: :route }]).map(&:source)
        end

        def refs_cache
          Gitlab::SafeRequestStore["banzai_#{parent_type}_refs".to_sym] ||= {}
        end

        def prepare_doc_for_scan
          filter.requires_unescaping? ? unescape_html_entities(html_content) : html_content
        end

        def html_content
          result[:rendered_html] ||= filter.doc.to_html
        end

        def unescape_html_entities(text)
          CGI.unescapeHTML(text.to_s)
        end
      end
    end
  end
end

Banzai::Filter::References::ReferenceCache.prepend_mod
