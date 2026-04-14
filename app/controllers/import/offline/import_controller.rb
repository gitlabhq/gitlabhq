# frozen_string_literal: true

module Import
  module Offline
    class ImportController < ApplicationController
      before_action :check_feature_flag

      feature_category :importers

      def show; end

      def history
        render_404
      end

      private

      def check_feature_flag
        render_404 if Feature.disabled?(:offline_transfer_ui, current_user) ||
          Feature.disabled?(:offline_transfer_imports, current_user)
      end
    end
  end
end
