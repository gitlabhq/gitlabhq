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
      result = { 'sections' => [] }

      result['title'] = options[:title] if options[:title]
      result['summary'] = options[:activity][:title]
      result['sections'] << {
        'activityTitle' => options[:activity][:title],
        'activitySubtitle' => options[:activity][:subtitle],
        'activityText' => options[:activity][:text],
        'activityImage' => options[:activity][:image]
      }

      if options[:attachments].present? && !options[:attachments].empty?
        result['sections'] << { 'title' => 'Details', 'facts' => attachments(options[:attachments]) }
      end

      result.to_json
    end

    def attachments(content)
      [{ 'name' => 'Attachments', 'value' => content }]
    end
  end
end
