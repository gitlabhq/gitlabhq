# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces issue references with links. References to
      # issues that do not exist are ignored.
      #
      # This filter supports cross-project references.
      #
      # When external issues tracker like Jira is activated we should not
      # use issue reference pattern, but we should still be able
      # to reference issues from other GitLab projects.
      class IssueReferenceFilter < IssuableReferenceFilter
        self.reference_type = :issue
        self.object_class   = Issue

        def url_for_object(issue, _parent)
          return issue_path(issue) if only_path?

          issue_url(issue)
        end

        def parent_records(parent, ids)
          # we are treating all group level issues as work items so those would be handled
          # by the WorkItemReferenceFilter
          return Issue.none if parent.is_a?(Group)

          parent.issues.where(iid: ids.to_a)
                .includes(:project, :namespace, ::Gitlab::Issues::TypeAssociationGetter.call)
        end

        def object_link_text_extras(issue, matches)
          super + design_link_extras(issue, matches.named_captures['path'])
        end

        def reference_class(object_sym, tooltip: false)
          super
        end

        def data_attributes_for(text, parent, object, **data)
          additional_attributes = { iid: object.iid, namespace_path: parent.full_path }
          if parent.is_a?(Namespaces::ProjectNamespace) || parent.is_a?(Project)
            additional_attributes[:project_path] = parent.full_path
          end

          super.merge(additional_attributes)
        end

        private

        def additional_object_attributes(issue)
          { issue_type: issue.work_item_type.base_type }
        end

        def issue_path(issue)
          Gitlab::UrlBuilder.build(issue, only_path: true)
        end

        def issue_url(issue)
          Gitlab::UrlBuilder.build(issue)
        end

        def design_link_extras(issue, path)
          if path == '/designs' && read_designs?(issue)
            ['designs']
          else
            []
          end
        end

        def read_designs?(issue)
          issue.project.design_management_enabled?
        end
      end
    end
  end
end
