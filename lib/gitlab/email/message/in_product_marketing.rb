# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        UnknownTrackError = Class.new(StandardError)

        TRACKS = [:create, :verify, :team, :trial].freeze

        def self.for(track)
          raise UnknownTrackError unless TRACKS.include?(track)

          "Gitlab::Email::Message::InProductMarketing::#{track.to_s.classify}".constantize
        end
      end
    end
  end
end
