# frozen_string_literal: true

module UserStatusTooltip
  extend ActiveSupport::Concern
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include EmojiHelper
  include ::UsersHelper

  included do
    expose :status_tooltip_html, if: ->(*) { status_loaded? } do |user|
      user_status(user)
    end

    expose :show_status do |user|
      status_loaded? && !!user.status&.customized?
    end

    expose :availability, if: ->(*) { status_loaded? } do |user|
      user.status&.availability
    end

    private

    def status_loaded?
      object.association(:status).loaded?
    end
  end
end
