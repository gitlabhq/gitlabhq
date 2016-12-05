module Gitlab::ChatCommands::Presenters
  class ListIssues < Gitlab::ChatCommands::Presenters::Base
    def present
      message = header_with_list("Multiple results found", issue_links)

      ephemeral_response(text: message)
    end

    private

    def issue_links
      @resource.map do |issue|
        "[#{issue.title}](#{url_for([namespace, project, issue])})"
      end
    end

    def project
      @project ||= @resource.first.project
    end

    def namespace
      @namespace ||= project.namespace.becomes(Namespace)
    end
  end
end
