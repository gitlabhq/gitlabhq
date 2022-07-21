# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class IssueEvent
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :id, :actor, :event, :commit_id, :label_title, :old_title, :new_title,
                         :milestone_title, :source, :assignee, :assigner, :created_at
        expose_attribute :issue_db_id # set in SingleEndpointIssueEventsImporter#each_associated

        # attributes - A Hash containing the event details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          { id: id }
        end

        class << self
          # Builds an event from a GitHub API response.
          #
          # event - An instance of `Sawyer::Resource` containing the event details.
          def from_api_response(event)
            new(
              id: event.id,
              actor: user_representation(event.actor),
              event: event.event,
              commit_id: event.commit_id,
              label_title: event.label && event.label[:name],
              old_title: event.rename && event.rename[:from],
              new_title: event.rename && event.rename[:to],
              milestone_title: event.milestone && event.milestone[:title],
              source: event.source,
              assignee: user_representation(event.assignee),
              assigner: user_representation(event.assigner),
              issue_db_id: event.issue_db_id,
              created_at: event.created_at
            )
          end

          # Builds an event using a Hash that was built from a JSON payload.
          def from_json_hash(raw_hash)
            hash = Representation.symbolize_hash(raw_hash)
            hash[:actor] = user_representation(hash[:actor], source: :hash)
            hash[:assignee] = user_representation(hash[:assignee], source: :hash)
            hash[:assigner] = user_representation(hash[:assigner], source: :hash)

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
