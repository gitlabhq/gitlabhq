module MicrosoftTeams
  class Notifier
    def initialize(webhook)
      @webhook = webhook
    end

    def ping(options = {})
      HTTParty.post(
        @webhook.to_str,
        headers: { 'Content-type' => 'application/json' },
        body: body(options)
      )
    end

    private

    def body(options = {})
      attachments = options[:attachments]
      result = { 'sections' => [] }

      result['title'] = options[:title]
      result['summary'] = options[:pretext]
      result['sections'] << options[:activity]

      result['sections'] << {
        'title' => 'Details',
        'facts' => [{ 'name' => 'Attachments', 'value' => attachments }]
      } if attachments.present? && attachments.empty?

      result.to_json
    end
  end
end
