module Ci
  module Admin
    class ApplicationController < Ci::ApplicationController
      before_filter :authenticate_user!
      before_filter :authenticate_admin!

      layout "ci/admin"
    end
  end
end
