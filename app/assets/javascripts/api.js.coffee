@Api =
  groups_path: "/api/:version/groups.json"
  group_path: "/api/:version/groups/:id.json"
  users_path: "/api/:version/users.json"
  user_path: "/api/:version/users/:id.json"
  notes_path: "/api/:version/projects/:id/notes.json"
  ldap_groups_path: "/api/:version/ldap/:provider/groups.json"
  namespaces_path: "/api/:version/namespaces.json"
  project_users_path: "/api/:version/projects/:id/users.json"
  projects_path: "/api/:version/projects.json"

  # Get 20 (depends on api) recent notes
  # and sort the ascending from oldest to newest
  notes: (project_id, callback) ->
    url = Api.buildUrl(Api.notes_path)
    url = url.replace(':id', project_id)

    $.ajax(
      url: url,
      data:
        private_token: gon.api_token
        gfm: true
        recent: true
      dataType: "json"
    ).done (notes) ->
      notes.sort (a, b) ->
        return a.id - b.id
      callback(notes)

  user: (user_id, callback) ->
    url = Api.buildUrl(Api.user_path)
    url = url.replace(':id', user_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (user) ->
      callback(user)

  # Return users list. Filtered by query
  # Only active users retrieved
  users: (query, skip_ldap, callback) ->
    url = Api.buildUrl(Api.users_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
        skip_ldap: skip_ldap
      dataType: "json"
    ).done (users) ->
      callback(users)

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
        active: true
      dataType: "json"
    ).done (users) ->
      callback(users)

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

  # Return LDAP groups list. Filtered by query
  ldap_groups: (query, provider, callback) ->
    url = Api.buildUrl(Api.ldap_groups_path)
    url = url.replace(':provider', provider);

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
        active: true
      dataType: "json"
    ).done (groups) ->
      callback(groups)

  # Return projects list. Filtered by query
  projects: (query, callback) ->
    project_url = Api.buildUrl(Api.projects_path)

    project_query = $.ajax(
      url: project_url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
      dataType: "json"
    ).done (projects) ->
      callback(projects)
