module MicrosoftTeams
  class Activity
    def initialize(title, subtitle, text, image)
      @title = title
      @subtitle = subtitle
      @text = text
      @image = image
    end

    def to_json
      {
        'activityTitle' => @title,
        'activitySubtitle' => @subtitle,
        'activityText' => @text,
        'activityImage' => @image
      }.to_json
    end
  end
end
