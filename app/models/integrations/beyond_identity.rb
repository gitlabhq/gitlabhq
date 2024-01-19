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

    def self.title
      'Beyond Identity'
    end

    def self.description
      s_('BeyondIdentity|Verify that GPG keys are authorized by Beyond Identity Authenticator.')
    end

    def self.help
      docs_link = ActionController::Base.helpers.link_to(
        _('Learn more'),
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/beyond_identity'),
        target: '_blank', rel: 'noopener noreferrer')

      format(_('Verify that GPG keys are authorized by Beyond Identity Authenticator. %{docs_link}').html_safe, # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
        docs_link: docs_link.html_safe) # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
    end

    def self.to_param
      'beyond_identity'
    end

    def self.supported_events
      %w[]
    end

    def inheritable?
      false
    end

    def execute(params)
      ::Gitlab::BeyondIdentity::Client.new(self).execute(params)
    end
  end
end
