module Users
  class TermsController < ApplicationController
    before_action :terms


    layout 'terms'

    def index
    end

    private

    def terms
      unless @terms = Gitlab::CurrentSettings.current_application_settings.latest_terms
        redirect_to request.referer || root_path
      end
    end
  end
end
