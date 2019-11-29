# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueSearch < Presenters::Base
        include Presenters::IssueBase

        def present
          text = if resource.count >= 5
                   "Here are the first 5 issues I found:"
                 elsif resource.one?
                   "Here is the only issue I found:"
                 else
                   "Here are the #{resource.count} issues I found:"
                 end

          ephemeral_response(text: text, attachments: attachments)
        end

        private

        def attachments
          resource.map do |issue|
            url = "[#{issue.to_reference}](#{url_for([namespace, project, issue])})"

            {
              color: color(issue),
              fallback: "#{issue.to_reference} #{issue.title}",
              text: "#{url} · #{issue.title} (#{status_text(issue)})",

              mrkdwn_in: [
                :text
              ]
            }
          end
        end

        def project
          @project ||= resource.first.project
        end

        def namespace
          @namespace ||= project.namespace.becomes(Namespace)
        end
      end
    end
  end
end
