# frozen_string_literal: true

# for secondary email confirmations - uses the same confirmation controller as :users
devise_for :emails, path: 'profile/emails', controllers: { confirmations: :confirmations }

resource :profile, only: [:show, :update] do
  member do
    get :audit_log
    get :applications, to: 'oauth/applications#index'

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

    resource :password, only: [:new, :create, :edit, :update] do
      member do
        put :reset
      end
    end
    resource :preferences, only: [:show, :update]

    resources :comment_templates, only: [:index, :show], action: :index

    resources :keys, only: [:index, :show, :create, :destroy] do
      member do
        delete :revoke
      end
    end

    resources :gpg_keys, only: [:index, :create, :destroy] do
      member do
        put :revoke
      end
    end
    resources :active_sessions, only: [:index, :destroy]
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

    resources :personal_access_tokens, only: [:index, :create] do
      member do
        put :revoke
      end
    end

    resource :two_factor_auth, only: [:show, :create, :destroy] do
      member do
        post :codes
        patch :skip
        post :create_webauthn
      end
    end

    resources :webauthn_registrations, only: [:destroy]
  end
end
