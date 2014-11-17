@Api =
  groups_path: "/api/:version/groups.json"
  group_path: "/api/:version/groups/:id.json"
  users_path: "/api/:version/users.json"
  user_path: "/api/:version/users/:id.json"
  notes_path: "/api/:version/projects/:id/notes.json"
  namespaces_path: "/api/:version/namespaces.json"

  group: (group_id, callback) ->
    url = Api.buildUrl(Api.group_path)
    url = url.replace(':id', group_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (group) ->
      callback(group)

  group: (group_id, callback) ->
    url = Api.buildUrl(Api.group_path)
    url = url.replace(':id', group_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (group) ->
      callback(group)

  # Return groups list. Filtered by query
  # Only active groups retrieved
  groups: (query, skip_ldap, callback) ->
    url = Api.buildUrl(Api.groups_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
      dataType: "json"
    ).done (groups) ->
      callback(groups)

  # Return project users list. Filtered by query
  # Only active users retrieved
  projectUsers: (project_id, query, callback) ->
    url = Api.buildUrl(Api.project_users_path)
    url = url.replace(':id', project_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
      dataType: "json"
    ).done (groups) ->
      callback(groups)

  # Return namespaces list. Filtered by query
  namespaces: (query, callback) ->
    url = Api.buildUrl(Api.namespaces_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
      dataType: "json"
    ).done (namespaces) ->
      callback(namespaces)

  buildUrl: (url) ->
    url = gon.relative_url_root + url if gon.relative_url_root?
    return url.replace(':version', gon.api_version)
