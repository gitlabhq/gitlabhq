# frozen_string_literal: true

module Integrations
  class SquashTm < Integration
    include HasWebHook

    field :url,
      placeholder: 'https://your-instance.squashcloud.io/squash/plugin/xsquash4gitlab/webhook/issue',
      title: -> { s_('SquashTmIntegration|Squash TM webhook URL') },
      description: -> { s_('URL of the Squash TM webhook.') },
      exposes_secrets: true,
      required: true

    field :token,
      type: :password,
      title: -> { s_('SquashTmIntegration|Secret token (optional)') },
      description: -> { s_('Secret token.') },
      non_empty_password_title: -> { s_('ProjectService|Enter new token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
      required: false

    with_options if: :activated? do
      validates :url, presence: true, public_url: true
      validates :token, length: { maximum: 255 }, allow_blank: true
    end

    def self.title
      'Squash TM'
    end

    def self.description
      s_("SquashTmIntegration|Update Squash TM requirements when GitLab issues are modified.")
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/squash_tm.md',
        s_("SquashTmIntegration|Update Squash TM requirements when GitLab issues are modified.")
      )
    end

    def self.supported_events
      %w[issue confidential_issue]
    end

    def self.to_param
      'squash_tm'
    end

    def self.default_test_event
      'issue'
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      execute_web_hook!(data, "#{data[:object_kind]} Hook")
    end

    def test(data)
      result = execute_web_hook!(data, "Test Configuration Hook")

      { success: result.payload[:http_status] == 200, result: result.message }
    rescue StandardError => error
      { success: false, result: error.message }
    end

    override :hook_url
    def hook_url
      format("#{url}%s", ('?token={token}' unless token.blank?))
    end

    def url_variables
      { 'token' => token }.compact
    end
  end
end
