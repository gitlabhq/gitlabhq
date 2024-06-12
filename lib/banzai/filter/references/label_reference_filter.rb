# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces label references with links.
      class LabelReferenceFilter < AbstractReferenceFilter
        self.reference_type = :label
        self.object_class   = Label

        def parent_records(parent, ids)
          return Label.none unless parent.is_a?(Project) || parent.is_a?(Group)

          relation = []

          # We need to handle relative and absolute paths separately
          labels_absolute_indexed = ids.group_by { |id| id[:absolute_path] }
          labels_absolute_indexed.each do |absolute_path, fitered_ids|
            label_ids = fitered_ids&.pluck(:label_id)&.compact

            if label_ids.present?
              relation << find_labels(parent, absolute_path: absolute_path).where(id: label_ids)
            end

            label_names = fitered_ids&.pluck(:label_name)&.compact
            if label_names.present?
              relation << find_labels(parent, absolute_path: absolute_path).where(name: label_names)
            end
          end

          relation.compact!
          return Label.none if relation.all?(Label.none)

          Label.from_union(relation)
        end

        def find_object(parent_object, id)
          key = reference_cache.records_per_parent[parent_object].keys.find do |k|
            k[:label_id] == id[:label_id] || k[:label_name] == id[:label_name]
          end

          reference_cache.records_per_parent[parent_object][key] if key
        end

        # Transform a symbol extracted from the text to a meaningful value
        #
        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `parse_symbol(ref) == record_identifier(record)`.
        #
        # This contract is slightly broken here, as we only have either the label_id
        # or the label_name, but not both.  But below, we have both pieces of information.
        # But it's accounted for in `find_object`
        def parse_symbol(symbol, match_data)
          absolute_path = !!match_data&.named_captures&.fetch('absolute_path')

          {
            label_id: match_data[:label_id]&.to_i,
            label_name: match_data[:label_name]&.tr('"', ''),
            absolute_path: absolute_path
          }
        end

        # We assume that most classes are identifying records by ID.
        #
        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `class.parse_symbol(ref) == record_identifier(record)`.
        # See note in `parse_symbol` above
        def record_identifier(record)
          { label_id: record.id, label_name: record.title }
        end

        def references_in(text, pattern = Label.reference_pattern)
          labels = {}

          unescaped_html = unescape_html_entities(text).gsub(pattern).with_index do |match, index|
            ident = identifier($~)
            label = yield match, ident, $~[:project], $~[:namespace], $~

            if label != match
              labels[index] = label
              "#{REFERENCE_PLACEHOLDER}#{index}"
            else
              match
            end
          end

          return text if labels.empty?

          escape_with_placeholders(unescaped_html, labels)
        end

        def find_labels(parent, absolute_path: false)
          params = label_finder_params(parent, absolute_path)

          LabelsFinder.new(nil, params).execute(skip_authorization: true)
        end

        def label_finder_params(parent, absolute_path)
          params = if parent.is_a?(Group)
                     { group_id: parent.id, only_group_labels: true }
                   else
                     { project: parent }
                   end

          params[:include_ancestor_groups] = !absolute_path

          params
        end

        def url_for_object(label, parent)
          label_url_method =
            if context[:label_url_method]
              context[:label_url_method]
            elsif parent.is_a?(Project)
              :project_issues_url
            elsif parent.is_a?(Group)
              :issues_group_url
            end

          label_url_method = :issues_group_url if parent.is_a?(Group) && label_url_method == :project_issues_url

          return unless label_url_method

          Gitlab::Routing.url_helpers.public_send(label_url_method, parent, label_name: label.name, only_path: context[:only_path]) # rubocop:disable GitlabSecurity/PublicSend
        end

        def object_link_text(object, matches)
          label_suffix = ''
          parent = project || group

          if matches[:absolute_path].blank? && (project || full_path_ref?(matches))
            project_path    = reference_cache.full_project_path(matches[:namespace], matches[:project], matches)
            parent_from_ref = from_ref_cached(project_path)
            reference       = parent_from_ref.to_human_reference(parent)

            label_suffix = " <i>in #{ERB::Util.html_escape(reference)}</i>" if reference.present?
          end

          presenter = object.present(issuable_subject: parent)
          LabelsHelper.render_colored_label(presenter, suffix: label_suffix)
        end

        def wrap_link(link, label)
          presenter = label.present(issuable_subject: project || group)
          LabelsHelper.wrap_label_html(link, label: presenter)
        end

        def full_path_ref?(matches)
          matches[:namespace] && matches[:project]
        end

        def reference_class(type, tooltip: true)
          super + ' gl-link gl-label-link'
        end

        def object_link_title(object, matches)
          presenter = object.present(issuable_subject: project || group)
          LabelsHelper.label_tooltip_title(presenter)
        end

        def parent
          project || group
        end

        def requires_unescaping?
          true
        end
      end
    end
  end
end

Banzai::Filter::References::LabelReferenceFilter.prepend_mod_with('Banzai::Filter::References::LabelReferenceFilter')
