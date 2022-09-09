# frozen_string_literal: true

module Gitlab
  module Nav
    class TopNavMenuHeader
      def self.build(title:)
        {
          type: :header,
          title: title
        }
      end
    end
  end
end
