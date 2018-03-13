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
          allow_local_requests: true,
          body: body(options)
        )

        result = true if response
      rescue Gitlab::HTTP::Error, StandardError => error
        Rails.logger.info("#{self.class.name}: Error while connecting to #{@webhook}: #{error.message}")
      end

      result
    end

    private

    def body(options = {})
      result = { 'sections' => [] }

      result['title'] = options[:title]
      result['summary'] = options[:pretext]
      result['sections'] << MicrosoftTeams::Activity.new(options[:activity]).prepare

      attachments = options[:attachments]
      unless attachments.blank?
        result['sections'] << {
          'title' => 'Details',
          'facts' => [{ 'name' => 'Attachments', 'value' => attachments }]
        }
      end

      result.to_json
    end
  end
end
