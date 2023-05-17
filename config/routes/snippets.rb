# frozen_string_literal: true

resources :snippets, except: [:create, :update, :destroy], concerns: :awardable, constraints: { id: /\d+/ } do
  member do
    get :raw
    post :mark_as_spam
  end

  collection do
    post :preview_markdown
  end

  scope module: :snippets do
    resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ } do
      member do
        delete :delete_attachment
      end
    end
  end
end

get '/snippets/:snippet_id/raw/:ref/*path',
  to: 'snippets/blobs#raw',
  as: :snippet_blob_raw,
  format: false,
  constraints: { snippet_id: /\d+/ }

get '/s/:username', to: redirect('users/%{username}/snippets'),
  constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }
