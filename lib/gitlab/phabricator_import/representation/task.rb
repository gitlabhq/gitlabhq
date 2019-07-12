# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Representation
      class Task
        def initialize(json)
          @json = json
        end

        def phabricator_id
          json['phid']
        end

        def author_phid
          json['fields']['authorPHID']
        end

        def owner_phid
          json['fields']['ownerPHID']
        end

        def phids
          @phids ||= [author_phid, owner_phid]
        end

        def issue_attributes
          @issue_attributes ||= {
            title: issue_title,
            description: issue_description,
            state: issue_state,
            created_at: issue_created_at,
            closed_at: issue_closed_at
          }
        end

        private

        attr_reader :json

        def issue_title
          # The 255 limit is the validation we impose on the Issue title in
          # Issuable
          @issue_title ||= json['fields']['name'].truncate(255)
        end

        def issue_description
          json['fields']['description']['raw']
        end

        def issue_state
          issue_closed_at.present? ? :closed : :opened
        end

        def issue_created_at
          return unless json['fields']['dateCreated']

          @issue_created_at ||= cast_datetime(json['fields']['dateCreated'])
        end

        def issue_closed_at
          return unless json['fields']['dateClosed']

          @issue_closed_at ||= cast_datetime(json['fields']['dateClosed'])
        end

        def cast_datetime(value)
          Time.at(value.to_i)
        end
      end
    end
  end
end
