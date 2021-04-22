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

        def url_for_object(issue, project)
          return issue_path(issue, project) if only_path?

          issue_url(issue, project)
        end

        def parent_records(parent, ids)
          parent.issues.where(iid: ids.to_a)
        end

        def object_link_text_extras(issue, matches)
          super + design_link_extras(issue, matches.named_captures['path'])
        end

        private

        def issue_path(issue, project)
          Gitlab::Routing.url_helpers.namespace_project_issue_path(namespace_id: project.namespace, project_id: project, id: issue.iid)
        end

        def issue_url(issue, project)
          Gitlab::Routing.url_helpers.namespace_project_issue_url(namespace_id: project.namespace, project_id: project, id: issue.iid)
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
