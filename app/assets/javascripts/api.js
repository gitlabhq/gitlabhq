(function() {
  this.Api = {
    groupsPath: "/api/:version/groups.json",
    groupPath: "/api/:version/groups/:id.json",
    namespacesPath: "/api/:version/namespaces.json",
    groupProjectsPath: "/api/:version/groups/:id/projects.json",
    projectsPath: "/api/:version/projects.json?simple=true",
    labelsPath: "/api/:version/projects/:id/labels",
    licensePath: "/api/:version/licenses/:key",
    gitignorePath: "/api/:version/gitignores/:key",
    gitlabCiYmlPath: "/api/:version/gitlab_ci_ymls/:key",
    issuableTemplatePath: "/:namespace_path/:project_path/templates/:type/:key",

    group: function(group_id, callback) {
      var url = Api.buildUrl(Api.groupPath)
        .replace(':id', group_id);
      return $.ajax({
        url: url,
        data: {
          private_token: gon.api_token
        },
        dataType: "json"
      }).done(function(group) {
        return callback(group);
      });
    },
    groups: function(query, skip_ldap, callback) {
      var url = Api.buildUrl(Api.groupsPath);
      return $.ajax({
        url: url,
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20
        },
        dataType: "json"
      }).done(function(groups) {
        return callback(groups);
      });
    },
    namespaces: function(query, callback) {
      var url = Api.buildUrl(Api.namespacesPath);
      return $.ajax({
        url: url,
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20
        },
        dataType: "json"
      }).done(function(namespaces) {
        return callback(namespaces);
      });
    },
    projects: function(query, order, callback) {
      var url = Api.buildUrl(Api.projectsPath);
      return $.ajax({
        url: url,
        data: {
          private_token: gon.api_token,
          search: query,
          order_by: order,
          per_page: 20
        },
        dataType: "json"
      }).done(function(projects) {
        return callback(projects);
      });
    },
    newLabel: function(project_id, data, callback) {
      var url = Api.buildUrl(Api.labelsPath)
        .replace(':id', project_id);
      data.private_token = gon.api_token;
      return $.ajax({
        url: url,
        type: "POST",
        data: data,
        dataType: "json"
      }).done(function(label) {
        return callback(label);
      }).error(function(message) {
        return callback(message.responseJSON);
      });
    },
    groupProjects: function(group_id, query, callback) {
      var url = Api.buildUrl(Api.groupProjectsPath)
        .replace(':id', group_id);
      return $.ajax({
        url: url,
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20
        },
        dataType: "json"
      }).done(function(projects) {
        return callback(projects);
      });
    },
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
    }
  };

}).call(this);
