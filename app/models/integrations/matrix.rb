# frozen_string_literal: true

module Integrations
  class Matrix < Integration
    include Base::ChatNotification

    MATRIX_HOSTNAME = "%{hostname}/_matrix/client/v3/rooms/%{roomId}/send/m.room.message/"

    field :hostname,
      section: SECTION_TYPE_CONNECTION,
      help: 'Custom hostname of the Matrix server. The default value is `https://matrix-client.matrix.org`.',
      placeholder: 'https://matrix-client.matrix.org',
      exposes_secrets: true,
      required: false

    field :token,
      section: SECTION_TYPE_CONNECTION,
      help: -> { s_('MatrixIntegration|Unique authentication token.') },
      non_empty_password_title: -> { s_('MatrixIntegration|New token') },
      non_empty_password_help: -> { s_('MatrixIntegration|Leave blank to use your current token.') },
      placeholder: 'syt-zyx57W2v1u123ew11',
      description: -> { _('The Matrix access token (for example, `syt-zyx57W2v1u123ew11`).') },
      exposes_secrets: true,
      is_secret: true,
      required: true

    field :room,
      title: 'Room identifier',
      section: SECTION_TYPE_CONFIGURATION,
      help: -> {
        _("Unique identifier for the target room (in the format `!qPKKM111FFKKsfoCVy:matrix.org`).")
      },
      placeholder: 'room ID',
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      description: -> { _('Send notifications for broken pipelines.') },
      help: 'If selected, successful pipelines do not trigger a notification event.'

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      description: -> {
                     _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
                       'and `default_and_protected`. The default value is `default`.')
                   },
      choices: -> { branch_choices }

    with_options if: :activated? do
      validates :token, :room, presence: true
      validates :webhook, presence: true, public_url: true
    end

    before_validation :set_webhook

    def self.title
      'Matrix notifications'
    end

    def self.description
      s_("MatrixIntegration|Send notifications about project events to Matrix.")
    end

    def self.to_param
      'matrix'
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/matrix.md',
        s_("MatrixIntegration|Send notifications about project events to Matrix.")
      )
    end

    def self.supported_events
      super - ['deployment']
    end

    private

    def set_webhook
      hostname = self.hostname.presence || 'https://matrix-client.matrix.org'

      return unless token.present? && room.present?

      self.webhook = format(MATRIX_HOSTNAME, hostname: hostname, roomId: room)
    end

    def notify(message, _opts)
      context = { no_sourcepos: true }.merge(project_level? ? { project: project } : { skip_project_check: true })

      body = {
        body: message.summary,
        msgtype: 'm.notice',
        format: 'org.matrix.custom.html',
        formatted_body: Banzai.render_and_post_process(message.summary, context)
      }.compact_blank

      header = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
      url = URI.parse(webhook)
      url.path << (Time.current.to_f * 1000).round.to_s
      response = Gitlab::HTTP.put(url, headers: header, body: Gitlab::Json.dump(body))

      response if response.success?
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end
