# frozen_string_literal: true

module API
  module Entities
    class UserStatus < Grape::Entity
      expose :emoji
      expose :message
      expose :availability
      expose :message_html do |entity|
        MarkupHelper.markdown_field(entity, :message)
      end
      expose :clear_status_at
    end
  end
end
