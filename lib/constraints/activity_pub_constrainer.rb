# frozen_string_literal: true

module Constraints
  class ActivityPubConstrainer
    def matches?(request)
      mime_types.any? { |m| request.headers['Accept'].include?(m) }
    end

    private

    def mime_types
      ['application/activity+json', 'application/ld+json; profile="https://www.w3.org/ns/activitystreams"']
    end
  end
end
