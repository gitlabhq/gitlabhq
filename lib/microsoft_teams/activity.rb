# frozen_string_literal: true

module MicrosoftTeams
  class Activity
    def initialize(title:, subtitle:, text:, image:)
      @title = title
      @subtitle = subtitle
      @text = text
      @image = image
    end

    def prepare
      {
        'activityTitle' => @title,
        'activitySubtitle' => @subtitle,
        'activityText' => @text,
        'activityImage' => @image
      }
    end
  end
end
