(() => {
  var Api = {
    groupsPath: '/api/:version/groups.json',
    groupPath: '/api/:version/groups/:id.json',
    namespacesPath: '/api/:version/namespaces.json',
    groupProjectsPath: '/api/:version/groups/:id/projects.json',
    projectsPath: '/api/:version/projects.json?simple=true',
    labelsPath: '/api/:version/projects/:id/labels',
    licensePath: '/api/:version/licenses/:key',
    gitignorePath: '/api/:version/gitignores/:key',
    gitlabCiYmlPath: '/api/:version/gitlab_ci_ymls/:key',
    issuePath: '/api/:version/project/:id/issue_templates/:key?private_token=:token',

    group: function group(groupId, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.groupPath).replace(':id', groupId),
        dataType: 'json',
        data: {
          private_token: gon.api_token
        }
      }).done((group) => {
          return callback(group);
      });
    },

    groups: function groups(query, skip_ldap, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.groupsPath),
        dataType: 'json',
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20
        }
      }).done((groups) => {
        return callback(groups);
      });
    },

    namespaces: function namespaces(query, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.namespacesPath),
        dataType: 'json',
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20
        }
      }).done((namespaces) => {
        return callback(namespaces);
      });
    },

    projects: function projects(query, order, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.projectsPath),
        dataType: 'json',
        data: {
          private_token: gon.api_token,
          search: query,
          order_by: order,
          per_page: 20
        }
      }).done((projects) => {
        return callback(projects);
      });
    },

    newLabel: function newLabel(projectId, data, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.labelsPath).replace(':id', projectId),
        type: 'POST',
        dataType: 'json',
        data: {
          private_token: gon.api_token
        }
      }).done((label) => {
        return callback(label);
      }).error((message) => {
        return callback(message.responseJSON);
      });
    },

    groupProjects: function groupProjects(groupId, query, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.groupProjectsPath).replace(':id', groupId),
        dataType: 'json',
        data: {
          private_token: gon.api_token,
          search: query,
          per_page: 20
        }
      }).done((projects) => {
        return callback(projects);
      });
    },

    licenseText: function licenseText(key, data, callback) {
      return $.ajax({
        url: Api.buildUrl(Api.licensePath).replace(':key', key),
        data: data
      }).done((license) => {
        return callback(license);
      });
    },

    gitignoreText: function gitignoreText(key, callback) {
      return $.get(Api.buildUrl(Api.gitignorePath).replace(':key', key),
      (gitignore) => {
        return callback(gitignore);
      });
    },

    gitlabCiYml: function gitlabCiYml(key, callback) {
      return $.get(Api.buildUrl(Api.gitlabCiYmlPath).replace(':key', key),
      (file) => {
        return callback(file);
      });
    },

    buildUrl: function buildUrl(url) {
      if (gon.relative_url_root) url = gon.relative_url_root + url;
      return url.replace(':version', gon.api_version);
    }
  };
})();
