# frozen_string_literal: true

module MicrosoftTeams
  class Notifier
    def initialize(webhook)
      @webhook = webhook
      @header = { 'Content-type' => 'application/json' }
    end

    def ping(options = {})
      result = false

      begin
        response = Gitlab::HTTP.post(
          @webhook.to_str,
          headers: @header,
          body: body(**options)
        )

        result = true if response
      rescue Gitlab::HTTP::Error, StandardError => error
        Gitlab::AppLogger.info("#{self.class.name}: Error while connecting to #{@webhook}: #{error.message}")
      end

      result
    end

    private

    def body(activity:, title: nil, attachments: nil)
      body = [
        {
          type: "TextBlock",
          text: title,
          weight: "bolder",
          size: "medium"
        }
      ]

      body << ::MicrosoftTeams::Activity.new(**activity).prepare

      unless attachments.blank?
        body << {
          type: "TextBlock",
          text: attachments,
          wrap: true
        }
      end

      {
        type: "message",
        'attachments' => [
          contentType: "application/vnd.microsoft.card.adaptive",
          content: { type: "AdaptiveCard", msteams: { width: "Full" }, version: "1.0", body: body }
        ]
      }.to_json
    end
  end
end
