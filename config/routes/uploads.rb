scope path: :uploads do
  # Note attachments and User/Group/Project avatars
  get "-/system/:model/:mounted_as/:id/:filename",
      to:           "uploads#show",
      constraints:  { model: /note|user|group|project/, mounted_as: /avatar|attachment/, filename: %r{[^/]+} }

  # show uploads for models, snippets (notes) available for now
  get '-/system/:model/:id/:secret/:filename',
    to: 'uploads#show',
    constraints: { model: /personal_snippet/, id: /\d+/, filename: %r{[^/]+} }

  # show temporary uploads
  get '-/system/temp/:secret/:filename',
    to: 'uploads#show',
    constraints: { filename: %r{[^/]+} }

  # Appearance
  get "-/system/:model/:mounted_as/:id/:filename",
      to:           "uploads#show",
      constraints:  { model: /appearance/, mounted_as: /logo|header_logo/, filename: /.+/ }

  # Project markdown uploads
  get ":namespace_id/:project_id/:secret/:filename",
    to:           "projects/uploads#show",
    constraints:  { namespace_id: /[a-zA-Z.0-9_\-]+/, project_id: /[a-zA-Z.0-9_\-]+/, filename: %r{[^/]+} }

  # create uploads for models, snippets (notes) available for now
  post ':model',
    to: 'uploads#create',
    constraints: { model: /personal_snippet/, id: /\d+/ },
    as: 'upload'
end

# Redirect old note attachments path to new uploads path.
get "files/note/:id/:filename",
  to:           redirect("uploads/note/attachment/%{id}/%{filename}"),
  constraints:  { filename: %r{[^/]+} }
