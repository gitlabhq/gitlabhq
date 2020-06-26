resources :snippets, concerns: :awardable do
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

# Use this /-/ scope for all new snippet routes.
scope path: '-' do
  get '/snippets/:snippet_id/raw/:ref/*path',
    to: 'snippets/blobs#raw',
    as: :snippet_blob_raw,
    format: false,
    constraints: { snippet_id: /\d+/ }
end

get '/s/:username', to: redirect('users/%{username}/snippets'),
                    constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }
