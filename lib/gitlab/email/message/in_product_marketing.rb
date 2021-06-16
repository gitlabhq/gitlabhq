# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        UnknownTrackError = Class.new(StandardError)

        def self.for(track)
          raise UnknownTrackError unless Namespaces::InProductMarketingEmailsService::TRACKS.key?(track)

          "Gitlab::Email::Message::InProductMarketing::#{track.to_s.classify}".constantize
        end
      end
    end
  end
end
