# frozen_string_literal: true

module ActivityPub
  class InboxResolverService
    attr_reader :subscription

    def initialize(subscription)
      @subscription = subscription
    end

    def execute
      profile = subscriber_profile
      unless profile.has_key?('inbox') && profile['inbox'].is_a?(String)
        raise ThirdPartyError, 'Inbox parameter absent or invalid'
      end

      subscription.subscriber_inbox_url = profile['inbox']
      subscription.shared_inbox_url = profile.dig('entrypoints', 'sharedInbox')
      subscription.save!
    end

    private

    def subscriber_profile
      raw_data = download_subscriber_profile

      begin
        profile = Gitlab::Json.parse(raw_data)
      rescue JSON::ParserError => e
        raise ThirdPartyError, e.message
      end

      profile
    end

    def download_subscriber_profile
      begin
        response = Gitlab::HTTP.get(subscription.subscriber_url,
          headers: {
            'Accept' => 'application/ld+json; profile="https://www.w3.org/ns/activitystreams"'
          }
        )
      rescue StandardError => e
        raise ThirdPartyError, e.message
      end

      response.body
    end
  end
end
