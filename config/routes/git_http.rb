scope constraints: { id: /.+\.git/, format: nil } do
  # Git HTTP clients ('git clone' etc.)
  get '/info/refs', to: 'git_http#info_refs'
  post '/git-upload-pack', to: 'git_http#git_upload_pack'
  post '/git-receive-pack', to: 'git_http#git_receive_pack'

  # Git LFS API (metadata)
  post '/info/lfs/objects/batch', to: 'lfs_api#batch'
  post '/info/lfs/objects', to: 'lfs_api#deprecated'
  get '/info/lfs/objects/*oid', to: 'lfs_api#deprecated'

  # GitLab LFS object storage
  scope constraints: { oid: /[a-f0-9]{64}/ } do
    get '/gitlab-lfs/objects/*oid', to: 'lfs_storage#download'

    scope constraints: { size: /[0-9]+/ } do
      put '/gitlab-lfs/objects/*oid/*size/authorize', to: 'lfs_storage#upload_authorize'
      put '/gitlab-lfs/objects/*oid/*size', to: 'lfs_storage#upload_finalize'
    end
  end
end

# Allow /info/refs, /info/refs?service=git-upload-pack, and
# /info/refs?service=git-receive-pack, but nothing else.
#
git_http_handshake = lambda do |request|
  request.query_string.blank? ||
    request.query_string.match(/\Aservice=git-(upload|receive)-pack\z/)
end

ref_redirect = redirect do |params, request|
  path = "#{params[:namespace_id]}/#{params[:project_id]}.git/info/refs"
  path << "?#{request.query_string}" unless request.query_string.blank?
  path
end

get '/info/refs', constraints: git_http_handshake, to: ref_redirect
