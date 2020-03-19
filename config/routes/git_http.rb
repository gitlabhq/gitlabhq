concern :gitactionable do
  scope(controller: :git_http) do
    get '/info/refs', action: :info_refs
    post '/git-upload-pack', action: :git_upload_pack
    post '/git-receive-pack', action: :git_receive_pack
  end
end

concern :lfsable do
  # Git LFS API (metadata)
  scope(path: 'info/lfs/objects', controller: :lfs_api) do
    post :batch
    post '/', action: :deprecated
    get '/*oid', action: :deprecated
  end

  scope(path: 'info/lfs') do
    resources :lfs_locks, controller: :lfs_locks_api, path: 'locks' do
      post :unlock, on: :member
      post :verify, on: :collection
    end
  end

  # GitLab LFS object storage
  scope(path: 'gitlab-lfs/objects/*oid', controller: :lfs_storage, constraints: { oid: /[a-f0-9]{64}/ }) do
    get '/', action: :download

    scope constraints: { size: /[0-9]+/ } do
      put '/*size/authorize', action: :upload_authorize
      put '/*size', action: :upload_finalize
    end
  end
end

# Git route for personal and project snippets
scope(path: ':namespace_id/:repository_id',
      format: nil,
      constraints: { namespace_id: Gitlab::PathRegex.personal_and_project_snippets_path_regex, repository_id: /\d+\.git/ },
      module: :repositories) do
  concerns :gitactionable
end

scope(path: '*namespace_id/:repository_id',
      format: nil,
      constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }) do
  scope(constraints: { repository_id: Gitlab::PathRegex.project_git_route_regex }) do
    scope(module: :repositories) do
      concerns :gitactionable
      concerns :lfsable
    end
  end

  # Redirect /group/project.wiki.git to the project wiki
  scope(format: true, constraints: { repository_id: Gitlab::PathRegex.project_wiki_git_route_regex, format: :git }) do
    wiki_redirect = redirect do |params, request|
      project_id = params[:repository_id].delete_suffix('.wiki')
      path = [params[:namespace_id], project_id, 'wikis'].join('/')
      path << "?#{request.query_string}" unless request.query_string.blank?
      path
    end

    get '/', to: wiki_redirect
  end

  # Redirect /group/project/info/refs to /group/project.git/info/refs
  scope(constraints: { repository_id: Gitlab::PathRegex.project_route_regex }) do
    # Allow /info/refs, /info/refs?service=git-upload-pack, and
    # /info/refs?service=git-receive-pack, but nothing else.
    #
    git_http_handshake = lambda do |request|
      ::Constraints::ProjectUrlConstrainer.new.matches?(request, existence_check: false) &&
        (request.query_string.blank? ||
         request.query_string.match(/\Aservice=git-(upload|receive)-pack\z/))
    end

    ref_redirect = redirect do |params, request|
      path = "#{params[:namespace_id]}/#{params[:repository_id]}.git/info/refs"
      path << "?#{request.query_string}" unless request.query_string.blank?
      path
    end

    get '/info/refs', constraints: git_http_handshake, to: ref_redirect
  end
end
