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
        type: "ColumnSet",
        columns: [
          {
            type: "Column",
            width: "auto",
            items: [
              {
                type: "Image",
                url: @image,
                size: "medium"
              }
            ]
          },
          {
            type: "Column",
            width: "stretch",
            items: [
              {
                type: "TextBlock",
                text: @title,
                weight: "bolder",
                wrap: true
              },
              {
                type: "TextBlock",
                text: @subtitle,
                isSubtle: true,
                wrap: true
              },
              {
                type: "TextBlock",
                text: @text,
                wrap: true
              }
            ]
          }
        ]
      }
    end
  end
end
