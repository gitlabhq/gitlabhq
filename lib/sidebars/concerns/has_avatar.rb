# frozen_string_literal: true

# This module has the necessary methods to show
# avatars next to the menu item.
module Sidebars
  module Concerns
    module HasAvatar
      def avatar
        nil
      end

      def avatar_shape
        'rect'
      end

      def entity_id
        nil
      end
    end
  end
end
