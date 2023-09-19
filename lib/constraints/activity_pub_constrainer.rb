# frozen_string_literal: true

module Constraints
  class ActivityPubConstrainer
    def matches?(request)
      accept = header(request)
      mime_types.any? { |m| accept.include?(m) }
    end

    private

    def mime_types
      ['application/activity+json', 'application/ld+json; profile="https://www.w3.org/ns/activitystreams"']
    end

    def header(request)
      request.headers['Accept'] || request.headers['Content-Type'] || ''
    end
  end
end
