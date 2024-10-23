# frozen_string_literal: true

module Projects
  module Packages
    class PackagesController < Projects::ApplicationController
      include PackagesAccess

      feature_category :package_registry
      urgency :low

      def index; end

      # The show action renders index to allow frontend routing to work on page refresh
      def show
        render :index
      end
    end
  end
end
