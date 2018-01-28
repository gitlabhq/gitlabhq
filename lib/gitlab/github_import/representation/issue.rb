# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class Issue
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :iid, :title, :description, :milestone_number,
                         :created_at, :updated_at, :state, :assignees,
                         :label_names, :author

        # Builds an issue from a GitHub API response.
        #
        # issue - An instance of `Sawyer::Resource` containing the issue
        #         details.
        def self.from_api_response(issue)
          user =
            if issue.user
              Representation::User.from_api_response(issue.user)
            end

          hash = {
            iid: issue.number,
            title: issue.title,
            description: issue.body,
            milestone_number: issue.milestone&.number,
            state: issue.state == 'open' ? :opened : :closed,
            assignees: issue.assignees.map do |u|
              Representation::User.from_api_response(u)
            end,
            label_names: issue.labels.map(&:name),
            author: user,
            created_at: issue.created_at,
            updated_at: issue.updated_at,
            pull_request: issue.pull_request ? true : false
          }

          new(hash)
        end

        # Builds a new issue using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          hash = Representation.symbolize_hash(raw_hash)

          hash[:state] = hash[:state].to_sym
          hash[:assignees].map! { |u| Representation::User.from_json_hash(u) }
          hash[:author] &&= Representation::User.from_json_hash(hash[:author])

          new(hash)
        end

        # attributes - A hash containing the raw issue details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def truncated_title
          title.truncate(255)
        end

        def labels?
          label_names && label_names.any?
        end

        def pull_request?
          attributes[:pull_request]
        end

        def issuable_type
          pull_request? ? 'MergeRequest' : 'Issue'
        end
      end
    end
  end
end
