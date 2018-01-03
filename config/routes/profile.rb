# for secondary email confirmations - uses the same confirmation controller as :users
devise_for :emails, path: 'profile/emails', controllers: { confirmations: :confirmations }

resource :profile, only: [:show, :update] do
  member do
    get :audit_log
    get :applications, to: 'oauth/applications#index'

    put :reset_incoming_email_token
    put :reset_rss_token
    put :update_username
  end

  scope module: :profiles do
    resource :account, only: [:show] do
      member do
        delete :unlink
      end
    end
    resource :notifications, only: [:show, :update]
    resource :password, only: [:new, :create, :edit, :update] do
      member do
        put :reset
      end
    end
    resource :preferences, only: [:show, :update]
    resources :keys, only: [:index, :show, :create, :destroy]
    resources :gpg_keys, only: [:index, :create, :destroy] do
      member do
        put :revoke
      end
    end
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
        post :create_u2f
        post :codes
        patch :skip
      end
    end

    resources :u2f_registrations, only: [:destroy]
  end
end
