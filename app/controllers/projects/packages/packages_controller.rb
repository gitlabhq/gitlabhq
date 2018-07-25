module Projects
  module Packages
    class PackagesController < ApplicationController
      before_action :authorize_admin_project!

      def index
        @packages = project.packages.all
      end
    end
  end
end
