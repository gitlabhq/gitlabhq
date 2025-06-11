# frozen_string_literal: true

module Integrations
  module Base
    module Pivotaltracker
      extend ActiveSupport::Concern

      API_ENDPOINT = 'https://www.pivotaltracker.com/services/v5/source_commits'

      class_methods do
        def title
          'Pivotal Tracker'
        end

        def description
          s_('PivotalTrackerService|Add commit messages as comments to Pivotal Tracker stories.')
        end

        def help
          build_help_page_url(
            'user/project/integrations/pivotal_tracker.md',
            s_("Add commit messages as comments to Pivotal Tracker stories.")
          )
        end

        def to_param
          'pivotaltracker'
        end

        def supported_events
          %w[push]
        end
      end

      included do
        validates :token, presence: true, if: :activated?

        field :token,
          type: :password,
          help: -> do
            s_('PivotalTrackerService|Pivotal Tracker API token. User must have access to the story. ' \
              'All comments are attributed to this user.')
          end,
          description: -> { _('The Pivotal Tracker token.') },
          non_empty_password_title: -> { s_('ProjectService|Enter new token') },
          non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
          required: true

        field :restrict_to_branch,
          title: -> { s_('Integrations|Restrict to branch (optional)') },
          help: -> do
            s_('PivotalTrackerService|Comma-separated list of branches to ' \
              'automatically inspect. Leave blank to include all branches.')
          end

        def execute(data)
          return unless supported_events.include?(data[:object_kind])
          return unless allowed_branch?(data[:ref])

          data[:commits].each do |commit|
            message = {
              'source_commit' => {
                'commit_id' => commit[:id],
                'author' => commit[:author][:name],
                'url' => commit[:url],
                'message' => commit[:message]
              }
            }
            Clients::HTTP.post(
              API_ENDPOINT,
              body: Gitlab::Json.dump(message),
              headers: {
                'Content-Type' => 'application/json',
                'X-TrackerToken' => token
              }
            )
          end
        end

        def avatar_url
          ActionController::Base
            .helpers
            .image_path('illustrations/third-party-logos/integrations-logos/pivotal-tracker.svg')
        end

        private

        def allowed_branch?(ref)
          return true unless ref.present? && restrict_to_branch.present?

          branch = Gitlab::Git.ref_name(ref)
          allowed_branches = restrict_to_branch.split(',').map(&:strip)

          branch.present? && allowed_branches.include?(branch)
        end
      end
    end
  end
end
