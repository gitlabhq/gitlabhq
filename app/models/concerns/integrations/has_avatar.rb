# frozen_string_literal: true

module Integrations
  module HasAvatar
    extend ActiveSupport::Concern

    def avatar_url
      ActionController::Base.helpers.image_path("illustrations/third-party-logos/integrations-logos/#{to_param}.svg")
    end
  end
end
