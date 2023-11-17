# frozen_string_literal: true

module ActivityPub
  class ApplicationController < ::ApplicationController
    include RoutableActions

    before_action :ensure_feature_flag
    skip_before_action :authenticate_user!
    after_action :set_content_type

    protect_from_forgery with: :null_session

    def can?(object, action, subject = :global)
      Ability.allowed?(object, action, subject)
    end

    def route_not_found
      head :not_found
    end

    def set_content_type
      self.content_type = "application/activity+json"
    end

    def ensure_feature_flag
      not_found unless ::Feature.enabled?(:activity_pub)
    end
  end
end
