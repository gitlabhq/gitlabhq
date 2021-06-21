# frozen_string_literal: true

module Integrations
  class Pivotaltracker < Integration
    include ActionView::Helpers::UrlHelper
    API_ENDPOINT = 'https://www.pivotaltracker.com/services/v5/source_commits'

    prop_accessor :token, :restrict_to_branch
    validates :token, presence: true, if: :activated?

    def title
      'Pivotal Tracker'
    end

    def description
      s_('PivotalTrackerService|Add commit messages as comments to Pivotal Tracker stories.')
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/pivotal_tracker'), target: '_blank', rel: 'noopener noreferrer'
      s_('Add commit messages as comments to Pivotal Tracker stories. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'pivotaltracker'
    end

    def fields
      [
        {
          type: 'text',
          name: 'token',
          help: s_('PivotalTrackerService|Pivotal Tracker API token. User must have access to the story. All comments are attributed to this user.'),
          required: true
        },
        {
          type: 'text',
          name: 'restrict_to_branch',
          title: 'Restrict to branch (optional)',
          help: s_('PivotalTrackerService|Comma-separated list of branches to ' \
            'automatically inspect. Leave blank to include all branches.')
        }
      ]
    end

    def self.supported_events
      %w(push)
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
        Gitlab::HTTP.post(
          API_ENDPOINT,
          body: message.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'X-TrackerToken' => token
          }
        )
      end
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
