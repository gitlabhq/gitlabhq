scope path: :uploads do
  # Note attachments and User/Group/Project avatars
  get ":model/:mounted_as/:id/:filename",
      to:           "uploads#show",
      constraints:  { model: /note|user|group|project/, mounted_as: /avatar|attachment/, filename: /[^\/]+/ }

  # Appearance
  get ":model/:mounted_as/:id/:filename",
      to:           "uploads#show",
      constraints:  { model: /appearance/, mounted_as: /logo|header_logo/, filename: /.+/ }

  # Project markdown uploads
  get ":namespace_id/:project_id/:secret/:filename",
    to:           "projects/uploads#show",
    constraints:  { namespace_id: /[a-zA-Z.0-9_\-]+/, project_id: /[a-zA-Z.0-9_\-]+/, filename: /[^\/]+/ }
end

# Redirect old note attachments path to new uploads path.
get "files/note/:id/:filename",
  to:           redirect("uploads/note/attachment/%{id}/%{filename}"),
  constraints:  { filename: /[^\/]+/ }
