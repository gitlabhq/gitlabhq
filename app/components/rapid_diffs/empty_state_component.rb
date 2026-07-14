# frozen_string_literal: true

module RapidDiffs
  class EmptyStateComponent < ViewComponent::Base
    def initialize(message: nil, description: nil, primary_button_text: nil, primary_button_link: nil)
      @message = message || _('There are no changes')
      @description = description
      @primary_button_text = primary_button_text
      @primary_button_link = primary_button_link
    end

    private

    attr_reader :message, :description, :primary_button_text, :primary_button_link

    def empty_state_options
      options = { svg_path: 'illustrations/empty-state/empty-commit-md.svg', title: message }

      if primary_button?
        options[:primary_button_text] = primary_button_text
        options[:primary_button_link] = primary_button_link
      end

      options
    end

    def primary_button?
      primary_button_text.present? && primary_button_link.present?
    end
  end
end
