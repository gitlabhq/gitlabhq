# frozen_string_literal: true

module RapidDiffs
  module Viewers
    class ViewerComponent < ViewComponent::Base
      def self.viewer_name
        raise NotImplementedError
      end

      def initialize(diff_file:)
        @diff_file = diff_file
      end

      def virtual_rendering_params
        nil
      end
    end
  end
end
