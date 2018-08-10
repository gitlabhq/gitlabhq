module Banzai
  module Filter
    # HTML filter that replaces project references with links.
    class ProjectReferenceFilter < ReferenceFilter
      self.reference_type = :project

      # Public: Find `namespace/project>` project references in text
      #
      #   ProjectReferenceFilter.references_in(text) do |match, project|
      #     "<a href=...>#{project}></a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, and the String project name.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(Project.markdown_reference_pattern) do |match|
          yield match, "#{$~[:namespace]}/#{$~[:project]}"
        end
      end

      def call
        ref_pattern = Project.markdown_reference_pattern
        ref_pattern_start = /\A#{ref_pattern}\z/

        nodes.each do |node|
          if text_node?(node)
            replace_text_when_pattern_matches(node, ref_pattern) do |content|
              project_link_filter(content)
            end
          elsif element_node?(node)
            yield_valid_link(node) do |link, inner_html|
              if link =~ ref_pattern_start
                replace_link_node_with_href(node, link) do
                  project_link_filter(link, link_content: inner_html)
                end
              end
            end
          end
        end

        doc
      end

      # Replace `namespace/project>` project references in text with links to the referenced
      # project page.
      #
      # text - String text to replace references in.
      # link_content - Original content of the link being replaced.
      #
      # Returns a String with `namespace/project>` references replaced with links. All links
      # have `gfm` and `gfm-project` class names attached for styling.
      def project_link_filter(text, link_content: nil)
        self.class.references_in(text) do |match, project_path|
          cached_call(:banzai_url_for_object, match, path: [Project, project_path.downcase]) do
            if project = projects_hash[project_path.downcase]
              link_to_project(project, link_content: link_content) || match
            else
              match
            end
          end
        end
      end

      # Returns a Hash containing all Project objects for the project
      # references in the current document.
      #
      # The keys of this Hash are the project paths, the values the
      # corresponding Project objects.
      def projects_hash
        @projects ||= Project.eager_load(:route, namespace: [:route])
                             .where_full_path_in(projects)
                             .index_by(&:full_path)
                             .transform_keys(&:downcase)
      end

      # Returns all projects referenced in the current document.
      def projects
        refs = Set.new

        nodes.each do |node|
          node.to_html.scan(Project.markdown_reference_pattern) do
            refs << "#{$~[:namespace]}/#{$~[:project]}"
          end
        end

        refs.to_a
      end

      private

      def urls
        Gitlab::Routing.url_helpers
      end

      def link_class
        reference_class(:project)
      end

      def link_to_project(project, link_content: nil)
        url = urls.project_url(project, only_path: context[:only_path])
        data = data_attribute(project: project.id)
        content = link_content || project.to_reference_with_postfix

        link_tag(url, data, content, project.name)
      end

      def link_tag(url, data, link_content, title)
        %(<a href="#{url}" #{data} class="#{link_class}" title="#{escape_once(title)}">#{link_content}</a>)
      end
    end
  end
end
