scope path: :uploads do
  # Note attachments and User/Group/Project avatars
  get "-/system/:model/:mounted_as/:id/:filename",
      to:           "uploads#show",
      constraints:  { model: /note|user|group|project/, mounted_as: /avatar|attachment/, filename: %r{[^/]+} }

  # show uploads for models, snippets (notes) available for now
  get '-/system/:model/:id/:secret/:filename',
    to: 'uploads#show',
    constraints: { model: /personal_snippet|user/, id: /\d+/, filename: %r{[^/]+} }

  # show temporary uploads
  get '-/system/temp/:secret/:filename',
    to: 'uploads#show',
    constraints: { filename: %r{[^/]+} }

  # Appearance
  get "-/system/:model/:mounted_as/:id/:filename",
      to:           "uploads#show",
      constraints:  { model: /appearance/, mounted_as: /logo|header_logo|favicon/, filename: /.+/ },
      as: 'appearance_upload'

  # Project markdown uploads
  # DEPRECATED: Remove this in GitLab 13.0 because this is redundant to show_namespace_project_uploads
  # https://gitlab.com/gitlab-org/gitlab/issues/196396
  get ":namespace_id/:project_id/:secret/:filename",
    to: redirect("%{namespace_id}/%{project_id}/uploads/%{secret}/%{filename}"),
    constraints:  { namespace_id: /[a-zA-Z.0-9_\-]+/, project_id: /[a-zA-Z.0-9_\-]+/, filename: %r{[^/]+} }, format: false, defaults: { format: nil }

  # create uploads for models, snippets (notes) available for now
  post ':model',
    to: 'uploads#create',
    constraints: { model: /personal_snippet|user/, id: /\d+/ },
    as: 'upload'

  post ':model/authorize',
    to: 'uploads#authorize',
    constraints: { model: /personal_snippet|user/ }
end

# Redirect old note attachments path to new uploads path.
get "files/note/:id/:filename",
  to:           redirect("uploads/note/attachment/%{id}/%{filename}"),
  constraints:  { filename: %r{[^/]+} }
