# frozen_string_literal: true

module Profiles
  class CommentTemplatesController < Profiles::ApplicationController
    feature_category :user_profile

    before_action do
      render_404 unless Feature.enabled?(:saved_replies, current_user)

      @hide_search_settings = true
    end
  end
end
