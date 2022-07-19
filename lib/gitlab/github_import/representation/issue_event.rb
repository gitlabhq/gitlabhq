# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class IssueEvent
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :id, :actor, :event, :commit_id, :label_title, :old_title, :new_title,
                         :source, :created_at
        expose_attribute :issue_db_id # set in SingleEndpointIssueEventsImporter#each_associated

        # Builds a event from a GitHub API response.
        #
        # event - An instance of `Sawyer::Resource` containing the event details.
        def self.from_api_response(event)
          new(
            id: event.id,
            actor: event.actor && Representation::User.from_api_response(event.actor),
            event: event.event,
            commit_id: event.commit_id,
            label_title: event.label && event.label[:name],
            old_title: event.rename && event.rename[:from],
            new_title: event.rename && event.rename[:to],
            source: event.source,
            issue_db_id: event.issue_db_id,
            created_at: event.created_at
          )
        end

        # Builds a event using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          hash = Representation.symbolize_hash(raw_hash)
          hash[:actor] &&= Representation::User.from_json_hash(hash[:actor])

          new(hash)
        end

        # attributes - A Hash containing the event details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          { id: id }
        end
      end
    end
  end
end
