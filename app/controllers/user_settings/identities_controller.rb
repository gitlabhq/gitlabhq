# frozen_string_literal: true

module UserSettings
  class IdentitiesController < ApplicationController
    feature_category :system_access

    before_action :verify_state, only: [:new]
    before_action :assign_variables_from_session
    before_action :verify_session_variables

    def new
      # rubocop:disable CodeReuse/ActiveRecord -- Specific use-case
      @identity = current_user.identities
                              .with_extern_uid(@provider, @extern_uid)
                              .first_or_initialize(extern_uid: @extern_uid)
      # rubocop:enable CodeReuse/ActiveRecord

      if @identity.persisted?
        delete_session_variables
        return redirect_to profile_account_path, notice: _('Identity already exists')
      end

      render layout: 'devise'
    end

    def create
      identity = current_user.identities.new(provider: @provider, extern_uid: @extern_uid)
      notice = if identity.save
                 _('Authentication method updated')
               else
                 format(_('Error linking identity: %{errors}'), errors: identity.errors.full_messages.to_sentence)
               end

      delete_session_variables
      redirect_to profile_account_path, notice: notice
    end

    private

    def verify_state
      render_403 unless session[:identity_link_state] == params[:state]
    end

    def assign_variables_from_session
      @provider = session[:identity_link_provider]
      @extern_uid = session[:identity_link_extern_uid]
    end

    def verify_session_variables
      return if @provider && @extern_uid

      delete_session_variables
      redirect_to profile_account_path,
        notice: _('Error linking identity: Provider and Extern UID must be in the session.')
    end

    def delete_session_variables
      session.delete(:identity_link_state)
      session.delete(:identity_link_provider)
      session.delete(:identity_link_extern_uid)
    end
  end
end
