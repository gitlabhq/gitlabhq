resources :snippets, concerns: :awardable do
  member do
    get :raw
    post :mark_as_spam
    post :preview_markdown
  end
end

get '/s/:username', to: redirect('/u/%{username}/snippets'),
                    constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }
