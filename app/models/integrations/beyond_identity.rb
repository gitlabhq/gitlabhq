# frozen_string_literal: true

module Integrations
  class BeyondIdentity < Integration
    validates :token, presence: true, if: :activated?

    field :token,
      type: :password,
      title: 'API token',
      help: -> {
              s_('BeyondIdentityService|API Token. User must have access to `git-commit-signing` endpoint.')
            },
      non_empty_password_title: -> { s_('ProjectService|Enter new API token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current API token.') },
      description: -> {
        s_('BeyondIdentityService|API Token. User must have access to `git-commit-signing` endpoint.')
      },
      required: true

    field :exclude_service_accounts,
      type: :checkbox,
      title: 'Exclude service accounts',
      help: -> {
        docs_link = ActionController::Base.helpers.link_to(
          _('service accounts'),
          Rails.application.routes.url_helpers.help_page_url('user/profile/service_accounts.md'),
          target: '_blank', rel: 'noopener noreferrer')

        format(s_(
          'BeyondIdentityService|If enabled, Beyond Identity will not check commits from %{docs_link}.'
        ).html_safe, docs_link: docs_link.html_safe) # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
      },
      description: -> {
        s_('BeyondIdentityService|If enabled, Beyond Identity will not check commits from service accounts.')
      }

    def self.title
      'Beyond Identity'
    end

    def self.description
      s_('BeyondIdentity|Verify that GPG keys are authorized by Beyond Identity Authenticator.')
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/beyond_identity.md',
        s_('Verify that GPG keys are authorized by Beyond Identity Authenticator.')
      )
    end

    def self.to_param
      'beyond_identity'
    end

    def self.supported_events
      %w[]
    end

    def self.activated_for_instance?
      !!::Integrations::BeyondIdentity.for_instance.first&.activated?
    end

    def self.instance_specific?
      true
    end

    def execute(params)
      ::Gitlab::BeyondIdentity::Client.new(self).execute(params)
    end
  end
end
