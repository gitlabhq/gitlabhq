module Mattermost
  class IssueService < BaseService
    def execute
      if params[:text].start_with?('create')
        create_issue
      else
        super
      end
    end

    private

    def create_issue
      issue = Issues::CreateService.new(project, current_user, issue_params).execute

      if issue.valid?
        generate_response(issue)
      else
        issue_create_error(issue.errors.full_messages)
      end
    end

    def issue_create_error(errors)
      {
        response_type: :ephemeral,
        text: "An error occured creating your issue: #{errors}"
      }
    end

    def collection
      project.issues
    end

    def link(issue)
      Gitlab::Routing.
        url_helpers.
        namespace_project_issue_url(project.namespace, project, issue)
    end

    def issue_params
      match = params[:text].match(/\Acreate (?<title>.+$)/)

      return issue_create_error("No title given") unless match

      {
        title: match[:title],
        description: params[:text].gsub(/\Acreate .+$\s*/, ''),
      }
    end
  end
end
