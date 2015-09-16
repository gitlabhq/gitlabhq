module Ci
  class HelpsController < Ci::ApplicationController
    skip_filter :check_config

    def show
    end

    def oauth2
      if valid_config?
        redirect_to ci_root_path
      else
        render layout: 'ci/empty'
      end
    end
  end
end
