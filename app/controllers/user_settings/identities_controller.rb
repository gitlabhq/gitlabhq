# frozen_string_literal: true

module UserSettings
  class IdentitiesController < ApplicationController
    feature_category :system_access

    before_action :verify_state, only: [:new]

    def new
      # rubocop:disable CodeReuse/ActiveRecord -- Specific use-case
      @identity = current_user.identities
                              .with_extern_uid(params[:provider], params[:extern_uid])
                              .first_or_initialize(extern_uid: params[:extern_uid])
      # rubocop:enable CodeReuse/ActiveRecord

      if @identity.persisted?
        session.delete(:identity_link_state)
        return redirect_to profile_account_path, notice: _('Identity already exists')
      end

      render layout: 'devise'
    end

    def create
      identity = current_user.identities.new(identity_params)
      notice = if identity.save
                 _('Authentication method updated')
               else
                 format(_('Error linking identity: %{errors}'), errors: identity.errors.full_messages.to_sentence)
               end

      session.delete(:identity_link_state)

      redirect_to profile_account_path, notice: notice
    end

    private

    def verify_state
      render_403 unless session[:identity_link_state] == params[:state]
    end

    def identity_params
      params.require(:identity).permit(:provider, :extern_uid)
    end
  end
end
