module Banzai
  module Filter
    # HTML filter that replaces label references with links.
    class LabelReferenceFilter < AbstractReferenceFilter
      self.reference_type = :label

      def self.object_class
        Label
      end

      def find_object(project, id)
        find_labels(project).find(id)
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
        find_labels(project).find_by(label_params)
      end

      def find_labels(project)
        LabelsFinder.new(nil, project_id: project.id).execute(skip_authorization: true)
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
        if same_group?(object) && namespace_match?(matches)
          render_same_project_label(object)
        elsif same_project?(object)
          render_same_project_label(object)
        else
          render_cross_project_label(object, matches)
        end
      end

      def same_group?(object)
        object.is_a?(GroupLabel) && object.group == project.group
      end

      def namespace_match?(matches)
        matches[:project].blank? || matches[:project] == project.path_with_namespace
      end

      def same_project?(object)
        object.is_a?(ProjectLabel) && object.project == project
      end

      def user
        context[:current_user] || context[:author]
      end

      def project
        context[:project]
      end

      def render_same_project_label(object)
        LabelsHelper.render_colored_label(object)
      end

      def render_cross_project_label(object, matches)
        source_project =
          if matches[:project]
            Project.find_with_namespace(matches[:project])
          else
            object.project
          end

        LabelsHelper.render_colored_cross_project_label(object, source_project)
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
