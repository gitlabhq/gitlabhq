# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces project references with links.
      class ProjectReferenceFilter < ReferenceFilter
        self.reference_type = :project
        self.object_class   = Project

        # Public: Find `namespace/project>` project references in text
        #
        #   references_in(text) do |match_text, project|
        #     "<a href=...>#{project}></a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String text match, and the String project name.
        #
        # Returns a HTML String with replacements made, or nil if no replacements were made.
        #
        # See ReferenceFilter#references_in for a detailed discussion.
        def references_in(text, pattern = object_reference_pattern)
          replace_references_in_text_with_html(Gitlab::Utils::Gsub.gsub_with_limit(text, pattern,
            limit: Banzai::Filter::FILTER_ITEM_LIMIT)) do |match_data|
            yield match_data[0], "#{match_data[:namespace]}/#{match_data[:project]}"
          end
        end

        private

        def object_reference_pattern
          @object_reference_pattern ||= Project.markdown_reference_pattern
        end

        # Replace `namespace/project>` project references in text with links to the referenced
        # project page.
        #
        # text - String text to replace references in.
        # link_content_html - Original HTML content of the link being replaced.
        #
        # Returns a String HTML with `namespace/project>` references replaced with links, or nil
        # if no replacements were made. All links have `gfm` and `gfm-project` class names attached for styling.
        def object_link_filter(text, pattern, link_content_html: nil, link_reference: false)
          references_in(text) do |match_text, project_path|
            cached_call(:banzai_url_for_object, match_text, path: [Project, project_path.downcase]) do
              if project = projects_hash[project_path.downcase]
                link_to_project(project, link_content_html: link_content_html)
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
                               .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
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

        def urls
          Gitlab::Routing.url_helpers
        end

        def link_class
          reference_class(:project)
        end

        def link_to_project(project, link_content_html: nil)
          url = urls.project_url(project, only_path: context[:only_path])
          data = data_attribute(project: project.id)
          content = link_content_html || CGI.escapeHTML(project.to_reference)

          write_opening_tag("a", {
            "href" => url,
            "title" => project.name,
            "class" => link_class,
            **data
          }) << content << "</a>"
        end
      end
    end
  end
end
