@Api =
  groupsPath: "/api/:version/groups.json"
  groupPath: "/api/:version/groups/:id.json"
  namespacesPath: "/api/:version/namespaces.json"
  groupProjectsPath: "/api/:version/groups/:id/projects.json"
  projectsPath: "/api/:version/projects.json"
  labelsPath: "/api/:version/projects/:id/labels"
  licensePath: "/api/:version/licenses/:key"
  gitignorePath: "/api/:version/gitignores/:key"
  gitlabCiYmlPath: "/api/:version/gitlab_ci_ymls/:key"

  group: (group_id, callback) ->
    url = Api.buildUrl(Api.groupPath)
    url = url.replace(':id', group_id)

    $.ajax(
      url: url
      dataType: "json"
    ).done (group) ->
      callback(group)

  # Return groups list. Filtered by query
  # Only active groups retrieved
  groups: (query, skip_ldap, callback) ->
    url = Api.buildUrl(Api.groupsPath)

    $.ajax(
      url: url
      data:
        search: query
        per_page: 20
      dataType: "json"
    ).done (groups) ->
      callback(groups)

  # Return namespaces list. Filtered by query
  namespaces: (query, callback) ->
    url = Api.buildUrl(Api.namespacesPath)

    $.ajax(
      url: url
      data:
        search: query
        per_page: 20
      dataType: "json"
    ).done (namespaces) ->
      callback(namespaces)

  # Return projects list. Filtered by query
  projects: (query, order, callback) ->
    url = Api.buildUrl(Api.projectsPath)

    $.ajax(
      url: url
      data:
        search: query
        order_by: order
        per_page: 20
      dataType: "json"
    ).done (projects) ->
      callback(projects)

  newLabel: (project_id, data, callback) ->
    url = Api.buildUrl(Api.labelsPath)
    url = url.replace(':id', project_id)

    $.ajax(
      url: url
      type: "POST"
      data: data
      dataType: "json"
    ).done (label) ->
      callback(label)
    .error (message) ->
      callback(message.responseJSON)

  # Return group projects list. Filtered by query
  groupProjects: (group_id, query, callback) ->
    url = Api.buildUrl(Api.groupProjectsPath)
    url = url.replace(':id', group_id)

    $.ajax(
      url: url
      data:
        search: query
        per_page: 20
      dataType: "json"
    ).done (projects) ->
      callback(projects)

  # Return text for a specific license
  licenseText: (key, data, callback) ->
    url = Api.buildUrl(Api.licensePath).replace(':key', key)

    $.ajax(
      url: url
      data: data
    ).done (license) ->
      callback(license)

  gitignoreText: (key, callback) ->
    url = Api.buildUrl(Api.gitignorePath).replace(':key', key)

    $.get url, (gitignore) ->
      callback(gitignore)

  gitlabCiYml: (key, callback) ->
    url = Api.buildUrl(Api.gitlabCiYmlPath).replace(':key', key)

    $.get url, (file) ->
      callback(file)

  buildUrl: (url) ->
    url = gon.relative_url_root + url if gon.relative_url_root?
    return url.replace(':version', gon.api_version)
