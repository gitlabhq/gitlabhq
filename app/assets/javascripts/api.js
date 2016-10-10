(function() {
  this.Api = {
    groupsPath: "/api/:version/groups.json",
    groupPath: "/api/:version/groups/:id.json",
    namespacesPath: "/api/:version/namespaces.json",
    groupProjectsPath: "/api/:version/groups/:id/projects.json",
    projectsPath: "/api/:version/projects.json?simple=true",
    labelsPath: "/:namespace_path/:project_path/labels",
    licensePath: "/api/:version/licenses/:key",
    gitignorePath: "/api/:version/gitignores/:key",
    ldapGroupsPath: "/api/:version/ldap/:provider/groups.json",
    gitlabCiYmlPath: "/api/:version/gitlab_ci_ymls/:key",
    issuableTemplatePath: "/:namespace_path/:project_path/templates/:type/:key",

    group: function(group_id, callback) {
      var url = Api.buildUrl(Api.groupPath)
        .replace(':id', group_id);
      return $.ajax({
        url: url,
        dataType: "json"
      }).done(function(group) {
        return callback(group);
      });
    },
    // Return groups list. Filtered by query
    groups: function(query, options, callback) {
      var url = Api.buildUrl(Api.groupsPath);
      return $.ajax({
        url: url,
        data: $.extend({
                search: query,
                per_page: 20
              }, options),
        dataType: "json"
      }).done(function(groups) {
        return callback(groups);
      });
    },
    // Return namespaces list. Filtered by query
    namespaces: function(query, callback) {
      var url = Api.buildUrl(Api.namespacesPath);
      return $.ajax({
        url: url,
        data: {
          search: query,
          per_page: 20
        },
        dataType: "json"
      }).done(function(namespaces) {
        return callback(namespaces);
      });
    },
    // Return projects list. Filtered by query
    projects: function(query, order, callback) {
      var url = Api.buildUrl(Api.projectsPath);
      return $.ajax({
        url: url,
        data: {
          search: query,
          order_by: order,
          per_page: 20
        },
        dataType: "json"
      }).done(function(projects) {
        return callback(projects);
      });
    },
    newLabel: function(namespace_path, project_path, data, callback) {
      var url = Api.buildUrl(Api.labelsPath)
        .replace(':namespace_path', namespace_path)
        .replace(':project_path', project_path);
      return $.ajax({
        url: url,
        type: "POST",
        data: {'label': data},
        dataType: "json"
      }).done(function(label) {
        return callback(label);
      }).error(function(message) {
        return callback(message.responseJSON);
      });
    },
    // Return group projects list. Filtered by query
    groupProjects: function(group_id, query, callback) {
      var url = Api.buildUrl(Api.groupProjectsPath)
        .replace(':id', group_id);
      return $.ajax({
        url: url,
        data: {
          search: query,
          per_page: 20
        },
        dataType: "json"
      }).done(function(projects) {
        return callback(projects);
      });
    },
    // Return text for a specific license
    licenseText: function(key, data, callback) {
      var url = Api.buildUrl(Api.licensePath)
        .replace(':key', key);
      return $.ajax({
        url: url,
        data: data
      }).done(function(license) {
        return callback(license);
      });
    },
    gitignoreText: function(key, callback) {
      var url = Api.buildUrl(Api.gitignorePath)
        .replace(':key', key);
      return $.get(url, function(gitignore) {
        return callback(gitignore);
      });
    },
    gitlabCiYml: function(key, callback) {
      var url = Api.buildUrl(Api.gitlabCiYmlPath)
        .replace(':key', key);
      return $.get(url, function(file) {
        return callback(file);
      });
    },
    issueTemplate: function(namespacePath, projectPath, key, type, callback) {
      var url = Api.buildUrl(Api.issuableTemplatePath)
        .replace(':key', key)
        .replace(':type', type)
        .replace(':project_path', projectPath)
        .replace(':namespace_path', namespacePath);
      $.ajax({
        url: url,
        dataType: 'json'
      }).done(function(file) {
        callback(null, file);
      }).error(callback);
    },
    buildUrl: function(url) {
      if (gon.relative_url_root != null) {
        url = gon.relative_url_root + url;
      }
      return url.replace(':version', gon.api_version);
    },
    ldap_groups: function(query, provider, callback) {
      var url;
      url = Api.buildUrl(Api.ldapGroupsPath);
      url = url.replace(':provider', provider);
      return $.ajax({
        url: url,
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20,
          active: true
        },
        dataType: "json"
      }).done(function(groups) {
        return callback(groups);
      });
    }
  };

}).call(this);
