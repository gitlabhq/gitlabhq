module Gitlab
  module Markdown
    # HTML filter that replaces label references with links.
    class LabelReferenceFilter < ReferenceFilter
      # Public: Find label references in text
      #
      #   LabelReferenceFilter.references_in(text) do |match, id, name|
      #     "<a href=...>#{Label.find(id)}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, an optional Integer label ID, and an optional
      # String label name.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(LABEL_PATTERN) do |match|
          yield match, $~[:label_id].to_i, $~[:label_name]
        end
      end

      # Pattern used to extract label references from text
      #
      # TODO (rspeicher): Limit to double quotes (meh) or disallow single quotes in label names (bad).
      LABEL_PATTERN = %r{
        ~(
          (?<label_id>\d+)   | # Integer-based label ID, or
          (?<label_name>
            [A-Za-z0-9_-]+   | # String-based single-word label title
            ['"][^&\?,]+['"]   # String-based multi-word label surrounded in quotes
          )
        )
      }x

      def call
        replace_text_nodes_matching(LABEL_PATTERN) do |content|
          label_link_filter(content)
        end
      end

      # Replace label references in text with links to the label specified.
      #
      # text - String text to replace references in.
      #
      # Returns a String with label references replaced with links. All links
      # have `gfm` and `gfm-label` class names attached for styling.
      def label_link_filter(text)
        project = context[:project]

        self.class.references_in(text) do |match, id, name|
          params = label_params(id, name)

          if label = project.labels.find_by(params)
            url = url_for_label(project, label)

            klass = reference_class(:label)

            %(<a href="#{url}" class="#{klass}">#{render_colored_label(label)}</a>)
          else
            match
          end
        end
      end

      def url_for_label(project, label)
        h = Rails.application.routes.url_helpers
        h.namespace_project_issues_path(project.namespace, project,
                                        label_name: label.name,
                                        only_path: context[:only_path])
      end

      def render_colored_label(label)
        LabelsHelper.render_colored_label(label)
      end

      # Parameters to pass to `Label.find_by` based on the given arguments
      #
      # id   - Integer ID to pass. If present, returns {id: id}
      # name - String name to pass. If `id` is absent, finds by name without
      #        surrounding quotes.
      #
      # Returns a Hash.
      def label_params(id, name)
        if id > 0
          { id: id }
        else
          # TODO (rspeicher): Don't strip single quotes if we decide to only use double quotes for surrounding.
          { name: name.tr('\'"', '') }
        end
      end
    end
  end
end
