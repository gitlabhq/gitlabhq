module Ci
  module Admin
    class ApplicationController < Ci::ApplicationController
      before_action :authenticate_user!
      before_action :authenticate_admin!

      layout "ci/admin"
    end
  end
end
