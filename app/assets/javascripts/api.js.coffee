@Api =
  groups_path: "/api/:version/groups.json"
  group_path: "/api/:version/groups/:id.json"
  namespaces_path: "/api/:version/namespaces.json"
  group_projects_path: "/api/:version/groups/:id/projects.json"
  projects_path: "/api/:version/projects.json"
  labels_path: "/api/:version/projects/:id/labels"

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

  newLabel: (project_id, data, callback) ->
    url = Api.buildUrl(Api.labels_path)
    url = url.replace(':id', project_id)

    data.private_token = gon.api_token
    $.ajax(
      url: url
      type: "POST"
      data: data
      dataType: "json"
    ).done (label) ->
      callback(label)

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
