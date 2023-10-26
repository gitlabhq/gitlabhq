# frozen_string_literal: true

module ActivityPub
  class AcceptFollowService
    MissingInboxURLError = Class.new(StandardError)

    attr_reader :subscription, :actor

    def initialize(subscription, actor)
      @subscription = subscription
      @actor = actor
    end

    def execute
      return if subscription.accepted?
      raise MissingInboxURLError unless subscription.subscriber_inbox_url.present?

      upload_accept_activity
      subscription.accepted!
    end

    private

    def upload_accept_activity
      body = Gitlab::Json::LimitedEncoder.encode(payload, limit: 1.megabyte)

      begin
        Gitlab::HTTP.post(subscription.subscriber_inbox_url, body: body, headers: headers)
      rescue StandardError => e
        raise ThirdPartyError, e.message
      end
    end

    def payload
      follow = subscription.payload.dup
      follow.delete('@context')

      {
        '@context': 'https://www.w3.org/ns/activitystreams',
        id: "#{actor}#follow/#{subscription.id}/accept",
        type: 'Accept',
        actor: actor,
        object: follow
      }
    end

    def headers
      {
        'User-Agent' => "GitLab/#{Gitlab::VERSION}",
        'Content-Type' => 'application/ld+json; profile="https://www.w3.org/ns/activitystreams"',
        'Accept' => 'application/ld+json; profile="https://www.w3.org/ns/activitystreams"'
      }
    end
  end
end
