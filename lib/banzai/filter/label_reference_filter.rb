module Banzai
  module Filter
    # HTML filter that replaces label references with links.
    class LabelReferenceFilter < AbstractReferenceFilter
      self.reference_type = :label

      def self.object_class
        Label
      end

      def find_object(project, id)
        project.labels.find(id)
      end

      def self.references_in(text, pattern = Label.reference_pattern)
        unescape_html_entities(text).gsub(pattern) do |match|
          yield match, $~[:label_id].to_i, $~[:label_name], $~[:project], $~
        end
      end

      def references_in(text, pattern = Label.reference_pattern)
        unescape_html_entities(text).gsub(pattern) do |match|
          label = find_label($~[:project], $~[:label_id], $~[:label_name])

          if label
            yield match, label.id, $~[:project], $~
          else
            match
          end
        end
      end

      def find_label(project_ref, label_id, label_name)
        project = project_from_ref(project_ref)
        return unless project

        label_params = label_params(label_id, label_name)
        project.labels.find_by(label_params)
      end

      # Parameters to pass to `Label.find_by` based on the given arguments
      #
      # id   - Integer ID to pass. If present, returns {id: id}
      # name - String name to pass. If `id` is absent, finds by name without
      #        surrounding quotes.
      #
      # Returns a Hash.
      def label_params(id, name)
        if name
          { name: name.tr('"', '') }
        else
          { id: id.to_i }
        end
      end

      def url_for_object(label, project)
        h = Gitlab::Routing.url_helpers
        h.namespace_project_issues_url(project.namespace, project, label_name: label.name,
                                                                   only_path:  context[:only_path])
      end

      def object_link_text(object, matches)
        if context[:project] == object.project
          LabelsHelper.render_colored_label(object)
        else
          LabelsHelper.render_colored_cross_project_label(object)
        end
      end

      def unescape_html_entities(text)
        CGI.unescapeHTML(text.to_s)
      end

      def object_link_title(object)
        # use title of wrapped element instead
        nil
      end
    end
  end
end
