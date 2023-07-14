# frozen_string_literal: true

module Pajamas
  class EmptyStateComponentPreview < ViewComponent::Preview
    # @param title text
    # @param description textarea
    # @param compact toggle
    # @param svg_path text
    # @param primary_button_text text
    # @param primary_button_link text
    # @param secondary_button_text text
    # @param secondary_button_link text
    def default(
      title: "This state is empty",
      description: "The title and message should be clear, concise, and explain why the user is seeing this screen.
        The actions should help the user on what to do to get the real feature.",
      compact: false,
      svg_path: "illustrations/empty-state/empty-projects-deleted-md.svg",
      primary_button_text: "Do primary action",
      primary_button_link: "#learn-more-primary",
      secondary_button_text: "Do secondary action",
      secondary_button_link: "#learn-more-secondary")
      render(Pajamas::EmptyStateComponent.new(
        title: title,
        svg_path: svg_path,
        primary_button_text: primary_button_text,
        primary_button_link: primary_button_link,
        secondary_button_text: secondary_button_text,
        secondary_button_link: secondary_button_link,
        compact: compact
      )) do |c|
        c.with_description { description } if description
      end
    end
  end
end
