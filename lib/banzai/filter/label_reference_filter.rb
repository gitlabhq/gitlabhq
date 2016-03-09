module Banzai
  module Filter
    # HTML filter that replaces label references with links.
    class LabelReferenceFilter < AbstractReferenceFilter
      def self.object_class
        Label
      end

      def find_object(project, id)
        project.labels.find(id)
      end

      def self.references_in(text, pattern = Label.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:label_id].to_i, $~[:label_name], $~[:project], $~
        end
      end

      def references_in(text, pattern = Label.reference_pattern)
        text.gsub(pattern) do |match|
          project = project_from_ref($~[:project])
          params = label_params($~[:label_id].to_i, $~[:label_name])
          label = project.labels.find_by(params)

          if label
            yield match, label.id, $~[:project], $~
          else
            match
          end
        end
      end

      def url_for_object(label, project)
        h = Gitlab::Application.routes.url_helpers
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
          { id: id }
        end
      end
    end
  end
end
