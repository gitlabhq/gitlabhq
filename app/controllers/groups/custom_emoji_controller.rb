# frozen_string_literal: true

module Groups
  class CustomEmojiController < Groups::ApplicationController
    feature_category :code_review_workflow
    urgency :low

    before_action do
      render_404 unless Feature.enabled?(:custom_emoji)
    end
  end
end
