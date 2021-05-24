# frozen_string_literal: true

module Integrations
  class Flowdock < Integration
    include ActionView::Helpers::UrlHelper

    prop_accessor :token
    validates :token, presence: true, if: :activated?

    def title
      'Flowdock'
    end

    def description
      s_('FlowdockService|Send event notifications from GitLab to Flowdock flows.')
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('api/services', anchor: 'flowdock'), target: '_blank', rel: 'noopener noreferrer'
      s_('FlowdockService|Send event notifications from GitLab to Flowdock flows. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'flowdock'
    end

    def fields
      [
        { type: 'text', name: 'token', placeholder: s_('FlowdockService|1b609b52537...'), required: true, help: 'Enter your Flowdock token.' }
      ]
    end

    def self.supported_events
      %w(push)
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      ::Flowdock::Git.post(
        data[:ref],
        data[:before],
        data[:after],
        token: token,
        repo: project.repository,
        repo_url: "#{Gitlab.config.gitlab.url}/#{project.full_path}",
        commit_url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/commit/%s",
        diff_url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/compare/%s...%s"
      )
    end
  end
end
