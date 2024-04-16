# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Reviewed < BaseImporter
          def execute(issue_event)
            review = Representation::PullRequestReview.from_json_hash(
              merge_request_iid: issue_event.issuable_id,
              author: issue_event.actor&.to_hash,
              note: issue_event.body.to_s,
              review_type: issue_event.state.upcase, # On timeline API, the state is in lower case
              submitted_at: issue_event.submitted_at,
              review_id: issue_event.id
            )

            PullRequests::ReviewImporter.new(review, project, client).execute({ add_reviewer: false })
          end
        end
      end
    end
  end
end
