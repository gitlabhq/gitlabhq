# frozen_string_literal: true

# for secondary email confirmations - uses the same confirmation controller as :users
devise_for :emails, path: 'profile/emails', controllers: { confirmations: :confirmations }

resource :profile, only: [] do
  member do
    get :audit_log, to: redirect('-/user_settings/authentication_log')
    get :applications, to: redirect('-/user_settings/applications')

    put :reset_incoming_email_token
    put :reset_feed_token
    put :reset_static_object_token
    put :update_username
  end

  scope module: :profiles do
    resource :account, only: [:show] do
      member do
        delete :unlink
      end
    end

    resource :notifications, only: [:show, :update] do
      scope(
        path: 'groups/*id',
        id: Gitlab::PathRegex.full_namespace_route_regex,
        as: :group,
        controller: :groups,
        constraints: { format: /(html|json)/ }
      ) do
        patch '/', action: :update
        put '/', action: :update
      end
    end

    resource :slack, only: [:edit] do
      member do
        get :slack_link
      end
    end

    resource :preferences, only: [:show, :update]

    resources :comment_templates, only: [:index, :show], action: :index

    resources :emails, only: [:index, :create, :destroy] do
      member do
        put :resend_confirmation_instructions
      end
    end

    resources :chat_names, only: [:index, :new, :create, :destroy] do
      collection do
        delete :deny
      end
    end

    resource :avatar, only: [:destroy]

    resource :two_factor_auth, only: [:show, :create, :destroy] do
      member do
        post :codes
        patch :skip
        post :create_webauthn
        delete :destroy_otp
        delete :destroy_webauthn, path: 'destroy_webauthn/:id'
      end
    end

    resources :usage_quotas, only: [:index]
  end
end
