# frozen_string_literal: true

module Profiles
  class CommentTemplatesController < Profiles::ApplicationController
    feature_category :user_profile

    before_action do
      @hide_search_settings = true
    end
  end
end
