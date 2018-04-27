module Users
  class TermsController < ApplicationController
    before_action :terms

    layout 'terms'

    def index
      @redirect = redirect_path
    end

    def accept
      agreement = Users::RespondToTermsService.new(current_user, viewed_term)
                    .execute(accepted: true)

      if agreement.persisted?
        redirect_to redirect_path
      else
        flash[:alert] = agreement.errors.full_messages.join(', ')
        redirect_to terms_path, redirect: redirect_path
      end
    end

    def decline
      agreement = Users::RespondToTermsService.new(current_user, viewed_term)
                    .execute(accepted: false)

      if agreement.persisted?
        sign_out(current_user)
        redirect_to root_path
      else
        flash[:alert] = agreement.errors.full_messages.join(', ')
        redirect_to terms_path, redirect: redirect_path
      end
    end

    private

    def viewed_term
      @viewed_term ||= ApplicationSetting::Term.find(params[:id])
    end

    def terms
      unless @term = Gitlab::CurrentSettings.current_application_settings.latest_terms
        redirect_to redirect_path
      end
    end

    def redirect_path
      referer = if request.referer && !request.referer.include?(terms_path)
                  URI(request.referer).path
                end

      params[:redirect] || referer || root_path
    end
  end
end
