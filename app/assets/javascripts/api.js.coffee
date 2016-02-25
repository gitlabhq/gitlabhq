@Api =
  groups_path: "/api/:version/groups.json"
  group_path: "/api/:version/groups/:id.json"
  namespaces_path: "/api/:version/namespaces.json"
  group_projects_path: "/api/:version/groups/:id/projects.json"
  projects_path: "/api/:version/projects.json"
  users_path: "/api/:version/users/:id.json"
  users_todos_path: "/api/:version/users/:id/todos.json"

  user: (user_id, callback) ->
    url = Api.buildUrl(Api.users_path)
    url = url.replace(':id', user_id)

    $.ajax(
      url: url,
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (user) ->
      callback(user)

  userTodos: (user_id, callback) ->
    url = Api.buildUrl(Api.users_todos_path)
    url = url.replace(':id', user_id)

    $.ajax(
      url: url,
      data:
        private_token: gon.api_token
      dataType: "json"
    ).done (user) ->
      callback(user)

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

  # Return projects list. Filtered by query
  projects: (query, order, callback) ->
    url = Api.buildUrl(Api.projects_path)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        order_by: order
        per_page: 20
      dataType: "json"
    ).done (projects) ->
      callback(projects)

  # Return group projects list. Filtered by query
  groupProjects: (group_id, query, callback) ->
    url = Api.buildUrl(Api.group_projects_path)
    url = url.replace(':id', group_id)

    $.ajax(
      url: url
      data:
        private_token: gon.api_token
        search: query
        per_page: 20
      dataType: "json"
    ).done (projects) ->
      callback(projects)

  buildUrl: (url) ->
    url = gon.relative_url_root + url if gon.relative_url_root?
    return url.replace(':version', gon.api_version)
