module Gitlab::ChatCommands::Presenters
  class ListIssues < Gitlab::ChatCommands::Presenters::Base
    def present
      ephemeral_response(text: "Here are the issues I found:", attachments: attachments)
    end

    private

    def attachments
      @resource.map do |issue|
        state = issue.open? ? "Open" : "Closed"

        {
          fallback: "Issue #{issue.to_reference}: #{issue.title}",
          color: "#d22852",
          text: "[#{issue.to_reference}](#{url_for([namespace, project, issue])}) · #{issue.title} (#{state})",
          mrkdwn_in: [
            "text"
          ]
        }
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
