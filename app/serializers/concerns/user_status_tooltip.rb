# frozen_string_literal: true

module UserStatusTooltip
  extend ActiveSupport::Concern
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include EmojiHelper
  include UsersHelper

  included do
    expose :user_status_if_loaded, as: :status_tooltip_html

    def user_status_if_loaded
      return nil unless object.association(:status).loaded?

      user_status(object)
    end
  end
end
