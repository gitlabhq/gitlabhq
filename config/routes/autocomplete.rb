# frozen_string_literal: true

scope '/autocomplete', controller: :autocomplete, as: :autocomplete do
  get '/users' => :users
  get '/users/:id' => :user, as: :user
  get '/projects' => :projects
  get '/award_emojis' => :award_emojis
  get '/merge_request_target_branches' => :merge_request_target_branches
  get '/merge_request_source_branches' => :merge_request_source_branches
  get '/deploy_keys_with_owners' => :deploy_keys_with_owners
end
