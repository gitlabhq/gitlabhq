# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        UnknownTrackError = Class.new(StandardError)

        def self.for(track)
          valid_tracks = [Namespaces::InviteTeamEmailService::TRACK, Namespaces::InProductMarketingEmailsService::TRACKS.keys].flatten
          raise UnknownTrackError unless valid_tracks.include?(track)

          "Gitlab::Email::Message::InProductMarketing::#{track.to_s.classify}".constantize
        end
      end
    end
  end
end
