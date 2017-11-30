module Banzai
  module Filter
    # Issues, Merge Requests, Snippets, Commits and Commit Ranges share
    # similar functionality in reference filtering.
    class AbstractReferenceFilter < ReferenceFilter
      include CrossProjectReference

      def self.object_class
        # Implement in child class
        # Example: MergeRequest
      end

      def self.object_name
        @object_name ||= object_class.name.underscore
      end

      def self.object_sym
        @object_sym ||= object_name.to_sym
      end

      # Public: Find references in text (like `!123` for merge requests)
      #
      #   AnyReferenceFilter.references_in(text) do |match, id, project_ref, matches|
      #     object = find_object(project_ref, id)
      #     "<a href=...>#{object.to_reference}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the Integer referenced object ID, an optional String
      # of the external project reference, and all of the matchdata.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text, pattern = object_class.reference_pattern)
        text.gsub(pattern) do |match|
          symbol = $~[object_sym]
          if object_class.reference_valid?(symbol)
            yield match, symbol.to_i, $~[:project], $~[:namespace], $~
          else
            match
          end
        end
      end

      def object_class
        self.class.object_class
      end

      def object_sym
        self.class.object_sym
      end

      def references_in(*args, &block)
        self.class.references_in(*args, &block)
      end

      # Implement in child class
      # Example: project.merge_requests.find
      def find_object(project, id)
      end

      # Override if the link reference pattern produces a different ID (global
      # ID vs internal ID, for instance) to the regular reference pattern.
      def find_object_from_link(project, id)
        find_object(project, id)
      end

      # Implement in child class
      # Example: project_merge_request_url
      def url_for_object(object, project)
      end

      def find_object_cached(project, id)
        cached_call(:banzai_find_object, id, path: [object_class, project.id]) do
          find_object(project, id)
        end
      end

      def find_object_from_link_cached(project, id)
        cached_call(:banzai_find_object_from_link, id, path: [object_class, project.id]) do
          find_object_from_link(project, id)
        end
      end

      def project_from_ref_cached(ref)
        cached_call(:banzai_project_refs, ref) do
          project_from_ref(ref)
        end
      end

      def url_for_object_cached(object, project)
        cached_call(:banzai_url_for_object, object, path: [object_class, project.id]) do
          url_for_object(object, project)
        end
      end

      def call
        return doc unless project || group

        ref_pattern = object_class.reference_pattern
        link_pattern = object_class.link_reference_pattern

        nodes.each do |node|
          if text_node?(node) && ref_pattern
            replace_text_when_pattern_matches(node, ref_pattern) do |content|
              object_link_filter(content, ref_pattern)
            end

          elsif element_node?(node)
            yield_valid_link(node) do |link, inner_html|
              if ref_pattern && link =~ /\A#{ref_pattern}\z/
                replace_link_node_with_href(node, link) do
                  object_link_filter(link, ref_pattern, link_content: inner_html)
                end

                next
              end

              next unless link_pattern

              if link == inner_html && inner_html =~ /\A#{link_pattern}/
                replace_link_node_with_text(node, link) do
                  object_link_filter(inner_html, link_pattern, link_reference: true)
                end

                next
              end

              if link =~ /\A#{link_pattern}\z/
                replace_link_node_with_href(node, link) do
                  object_link_filter(link, link_pattern, link_content: inner_html, link_reference: true)
                end

                next
              end
            end
          end
        end

        doc
      end

      # Replace references (like `!123` for merge requests) in text with links
      # to the referenced object's details page.
      #
      # text - String text to replace references in.
      # pattern - Reference pattern to match against.
      # link_content - Original content of the link being replaced.
      # link_reference - True if this was using the link reference pattern,
      #                  false otherwise.
      #
      # Returns a String with references replaced with links. All links
      # have `gfm` and `gfm-OBJECT_NAME` class names attached for styling.
      def object_link_filter(text, pattern, link_content: nil, link_reference: false)
        references_in(text, pattern) do |match, id, project_ref, namespace_ref, matches|
          project_path = full_project_path(namespace_ref, project_ref)
          project = project_from_ref_cached(project_path)

          if project
            object =
              if link_reference
                find_object_from_link_cached(project, id)
              else
                find_object_cached(project, id)
              end
          end

          if object
            title = object_link_title(object)
            klass = reference_class(object_sym)

            data = data_attributes_for(link_content || match, project, object, link: !!link_content)

            url =
              if matches.names.include?("url") && matches[:url]
                matches[:url]
              else
                url_for_object_cached(object, project)
              end

            content = link_content || object_link_text(object, matches)

            %(<a href="#{url}" #{data}
                 title="#{escape_once(title)}"
                 class="#{klass}">#{content}</a>)
          else
            match
          end
        end
      end

      def data_attributes_for(text, project, object, link: false)
        data_attribute(
          original:     text,
          link:         link,
          project:      project.id,
          object_sym => object.id
        )
      end

      def object_link_text_extras(object, matches)
        extras = []

        if matches.names.include?("anchor") && matches[:anchor] && matches[:anchor] =~ /\A\#note_(\d+)\z/
          extras << "comment #{$1}"
        end

        extras
      end

      def object_link_title(object)
        object.title
      end

      def object_link_text(object, matches)
        parent = context[:project] || context[:group]
        text = object.reference_link_text(parent)

        extras = object_link_text_extras(object, matches)
        text += " (#{extras.join(", ")})" if extras.any?

        text
      end

      # Returns a Hash containing all object references (e.g. issue IDs) per the
      # project they belong to.
      def references_per_project
        @references_per_project ||= begin
          refs = Hash.new { |hash, key| hash[key] = Set.new }

          regex = Regexp.union(object_class.reference_pattern, object_class.link_reference_pattern)

          nodes.each do |node|
            node.to_html.scan(regex) do
              project_path = full_project_path($~[:namespace], $~[:project])
              symbol = $~[object_sym]
              refs[project_path] << symbol if object_class.reference_valid?(symbol)
            end
          end

          refs
        end
      end

      # Returns a Hash containing referenced projects grouped per their full
      # path.
      def projects_per_reference
        @projects_per_reference ||= begin
          refs = Set.new

          references_per_project.each do |project_ref, _|
            refs << project_ref
          end

          find_projects_for_paths(refs.to_a).index_by(&:full_path)
        end
      end

      def projects_relation_for_paths(paths)
        Project.where_full_path_in(paths).includes(:namespace)
      end

      # Returns projects for the given paths.
      def find_projects_for_paths(paths)
        if RequestStore.active?
          cache = project_refs_cache
          to_query = paths - cache.keys

          unless to_query.empty?
            projects = projects_relation_for_paths(to_query)

            found = []
            projects.each do |project|
              ref = project.full_path
              get_or_set_cache(cache, ref) { project }
              found << ref
            end

            not_found = to_query - found
            not_found.each do |ref|
              get_or_set_cache(cache, ref) { nil }
            end
          end

          cache.slice(*paths).values.compact
        else
          projects_relation_for_paths(paths)
        end
      end

      def current_project_path
        return unless project

        @current_project_path ||= project.full_path
      end

      def current_project_namespace_path
        return unless project

        @current_project_namespace_path ||= project.namespace.full_path
      end

      private

      def full_project_path(namespace, project_ref)
        return current_project_path unless project_ref

        namespace_ref = namespace || current_project_namespace_path
        "#{namespace_ref}/#{project_ref}"
      end

      def project_refs_cache
        RequestStore[:banzai_project_refs] ||= {}
      end
    end
  end
end
