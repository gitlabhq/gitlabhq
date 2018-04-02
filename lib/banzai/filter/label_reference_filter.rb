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
          yield match, $~[:label_id].to_i, $~[:label_name], $~[:project], $~[:namespace], $~
        end
      end

      def references_in(text, pattern = Label.reference_pattern)
        unescape_html_entities(text).gsub(pattern) do |match|
          namespace, project = $~[:namespace], $~[:project]
          project_path = full_project_path(namespace, project)
          label = find_label(project_path, $~[:label_id], $~[:label_name])

          if label
            yield match, label.id, project, namespace, $~
          else
            match
          end
        end
      end

      def find_label(project_ref, label_id, label_name)
        project = parent_from_ref(project_ref)
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
        h.project_issues_url(project, label_name: label.name, only_path: context[:only_path])
      end

      def object_link_text(object, matches)
        project_path     = full_project_path(matches[:namespace], matches[:project])
        project_from_ref = from_ref_cached(project_path)
        reference        = project_from_ref.to_human_reference(project)
        label_suffix     = " <i>in #{reference}</i>" if reference.present?

        LabelsHelper.render_colored_label(object, label_suffix)
      end

      def unescape_html_entities(text)
        CGI.unescapeHTML(text.to_s)
      end

      def object_link_title(object, matches)
        # use title of wrapped element instead
        nil
      end
    end
  end
end
