# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class IssueEvent
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :id, :actor, :event, :commit_id, :label_title, :old_title, :new_title,
                         :milestone_title, :issue, :source, :assignee, :review_requester,
                         :requested_reviewer, :created_at

        # attributes - A Hash containing the event details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          {
            id: id,
            issuable_iid: issuable_id,
            event: event
          }
        end

        def issuable_type
          issue && issue[:pull_request].present? ? 'MergeRequest' : 'Issue'
        end

        def issuable_id
          issue && issue[:number]
        end

        class << self
          # Builds an event from a GitHub API response.
          #
          # event - An instance of `Hash` containing the event details.
          def from_api_response(event, additional_data = {})
            new(
              id: event[:id],
              actor: user_representation(event[:actor]),
              event: event[:event],
              commit_id: event[:commit_id],
              label_title: event.dig(:label, :name),
              old_title: event.dig(:rename, :from),
              new_title: event.dig(:rename, :to),
              milestone_title: event.dig(:milestone, :title),
              issue: event[:issue],
              source: event[:source],
              assignee: user_representation(event[:assignee]),
              requested_reviewer: user_representation(event[:requested_reviewer]),
              review_requester: user_representation(event[:review_requester]),
              created_at: event[:created_at]
            )
          end

          # Builds an event using a Hash that was built from a JSON payload.
          def from_json_hash(raw_hash)
            hash = Representation.symbolize_hash(raw_hash)
            hash[:actor] = user_representation(hash[:actor], source: :hash)
            hash[:assignee] = user_representation(hash[:assignee], source: :hash)
            hash[:requested_reviewer] = user_representation(hash[:requested_reviewer], source: :hash)
            hash[:review_requester] = user_representation(hash[:review_requester], source: :hash)

            new(hash)
          end

          private

          def user_representation(data, source: :api_response)
            return unless data

            case source
            when :api_response
              Representation::User.from_api_response(data)
            when :hash
              Representation::User.from_json_hash(data)
            end
          end
        end
      end
    end
  end
end
