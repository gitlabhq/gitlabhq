module Mattermost
  class IssueService < BaseService
    SUBCOMMANDS = ['create', 'search'].freeze

    def execute
      resource  = if resource_id
                    find_resource
                  elsif subcommand
                    send(subcommand)
                  else
                    nil
                  end

      generate_response(resource)
    end

    private

    def find_resource
      return nil unless can?(current_user, :read_issue, project)

      collection.find_by(iid: resource_id)
    end

    def create
      return nil unless can?(current_user, :create_issue, project)

      Issues::CreateService.new(project, current_user, issue_params).execute
    end

    def search
      return nil unless can?(current_user, :read_issue, project)

      query = params[:text].gsub(/\Asearch /, '')
      collection.search(query).limit(5)
    end

    def issue_create_error(errors)
      {
        response_type: :ephemeral,
        text: "An error occured creating your issue: #{errors}" #TODO; this displays an array
      }
    end

    def single_resource(issue)
      return issue_create_error(issue) if issue.errors.any?

      message = "### [#{issue.to_reference} #{issue.title}](#{link(issue)})"
      message << "\n\n#{issue.description}" if issue.description

      {
        response_type: :in_channel,
        text: message
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
        description: params[:text].gsub(/\Acreate .+$\s*/, '')
      }
    end

    def subcommand
      match = params[:text].match(/\A(?<subcommand>(#{SUBCOMMANDS.join('|')}))/)

      match ? match[:subcommand] : nil
    end
  end
end
