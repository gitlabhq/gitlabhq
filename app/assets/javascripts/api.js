import $ from 'jquery';

const Api = {
  groupsPath: '/api/:version/groups.json',
  groupPath: '/api/:version/groups/:id.json',
  namespacesPath: '/api/:version/namespaces.json',
  groupProjectsPath: '/api/:version/groups/:id/projects.json',
  projectsPath: '/api/:version/projects.json?simple=true',
  labelsPath: '/:namespace_path/:project_path/labels',
  licensePath: '/api/:version/templates/licenses/:key',
  gitignorePath: '/api/:version/templates/gitignores/:key',
  gitlabCiYmlPath: '/api/:version/templates/gitlab_ci_ymls/:key',
  ldapGroupsPath: '/api/:version/ldap/:provider/groups.json',
  dockerfilePath: '/api/:version/templates/dockerfiles/:key',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  usersPath: '/api/:version/users.json',
  commitPath: '/api/:version/projects/:id/repository/commits',

  group(groupId, callback) {
    const url = Api.buildUrl(Api.groupPath)
      .replace(':id', groupId);
    return $.ajax({
      url,
      dataType: 'json',
    })
      .done(group => callback(group));
  },

  // Return groups list. Filtered by query
  groups(query, options, callback = $.noop) {
    const url = Api.buildUrl(Api.groupsPath);
    return $.ajax({
      url,
      data: Object.assign({
        search: query,
        per_page: 20,
      }, options),
      dataType: 'json',
    })
      .done(groups => callback(groups));
  },

  // Return namespaces list. Filtered by query
  namespaces(query, callback) {
    const url = Api.buildUrl(Api.namespacesPath);
    return $.ajax({
      url,
      data: {
        search: query,
        per_page: 20,
      },
      dataType: 'json',
    }).done(namespaces => callback(namespaces));
  },

  // Return projects list. Filtered by query
  projects(query, options, callback) {
    const url = Api.buildUrl(Api.projectsPath);
    return $.ajax({
      url,
      data: Object.assign({
        search: query,
        per_page: 20,
        membership: true,
      }, options),
      dataType: 'json',
    })
      .done(projects => callback(projects));
  },

  newLabel(namespacePath, projectPath, data, callback) {
    const url = Api.buildUrl(Api.labelsPath)
      .replace(':namespace_path', namespacePath)
      .replace(':project_path', projectPath);
    return $.ajax({
      url,
      type: 'POST',
      data: { label: data },
      dataType: 'json',
    })
      .done(label => callback(label))
      .fail(message => callback(message.responseJSON));
  },

  // Return group projects list. Filtered by query
  groupProjects(groupId, query, callback) {
    const url = Api.buildUrl(Api.groupProjectsPath)
      .replace(':id', groupId);
    return $.ajax({
      url,
      data: {
        search: query,
        per_page: 20,
      },
      dataType: 'json',
    })
      .done(projects => callback(projects));
  },

  commitMultiple(id, data, callback) {
    const url = Api.buildUrl(Api.commitPath)
      .replace(':id', id);
    return $.ajax({
      url,
      type: 'POST',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(data),
      dataType: 'json',
    })
      .done(commitData => callback(commitData))
      .fail(message => callback(message.responseJSON));
  },

  // Return text for a specific license
  licenseText(key, data, callback) {
    const url = Api.buildUrl(Api.licensePath)
      .replace(':key', key);
    return $.ajax({
      url,
      data,
    })
      .done(license => callback(license));
  },

  gitignoreText(key, callback) {
    const url = Api.buildUrl(Api.gitignorePath)
      .replace(':key', key);
    return $.get(url, gitignore => callback(gitignore));
  },

  gitlabCiYml(key, callback) {
    const url = Api.buildUrl(Api.gitlabCiYmlPath)
      .replace(':key', key);
    return $.get(url, file => callback(file));
  },

  dockerfileYml(key, callback) {
    const url = Api.buildUrl(Api.dockerfilePath).replace(':key', key);
    $.get(url, callback);
  },

  issueTemplate(namespacePath, projectPath, key, type, callback) {
    const url = Api.buildUrl(Api.issuableTemplatePath)
      .replace(':key', key)
      .replace(':type', type)
      .replace(':project_path', projectPath)
      .replace(':namespace_path', namespacePath);
    $.ajax({
      url,
      dataType: 'json',
    })
      .done(file => callback(null, file))
      .fail(callback);
  },

  users(query, options) {
    const url = Api.buildUrl(this.usersPath);
    return Api.wrapAjaxCall({
      url,
      data: Object.assign({
        search: query,
        per_page: 20,
      }, options),
      dataType: 'json',
    });
  },

  approverUsers(search, options, callback = $.noop) {
    const url = Api.buildUrl('/autocomplete/users.json');
    return $.ajax({
      url,
      data: $.extend({
        search,
        per_page: 20,
      }, options),
      dataType: 'json',
    }).done(callback);
  },

  ldap_groups(query, provider, callback) {
    const url = Api.buildUrl(this.ldapGroupsPath).replace(':provider', provider);
    return Api.wrapAjaxCall({
      url,
      data: Object.assign({
        private_token: gon.api_token,
        search: query,
        per_page: 20,
        active: true,
      }),
      dataType: 'json',
    }).then(groups => callback(groups));
  },

  buildUrl(url) {
    let urlRoot = '';
    if (gon.relative_url_root != null) {
      urlRoot = gon.relative_url_root;
    }
    return urlRoot + url.replace(':version', gon.api_version);
  },

  wrapAjaxCall(options) {
    return new Promise((resolve, reject) => {
      // jQuery 2 is not Promises/A+ compatible (missing catch)
      $.ajax(options) // eslint-disable-line promise/catch-or-return
      .then(data => resolve(data),
        (jqXHR, textStatus, errorThrown) => {
          const error = new Error(`${options.url}: ${errorThrown}`);
          error.textStatus = textStatus;
          reject(error);
        },
      );
    });
  },
};

export default Api;
