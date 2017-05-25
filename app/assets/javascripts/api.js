<<<<<<< HEAD
/* eslint-disable func-names, space-before-function-paren, quotes, object-shorthand, camelcase, no-var, comma-dangle, prefer-arrow-callback, quote-props, no-param-reassign, max-len */

var Api = {
=======
import $ from 'jquery';

const Api = {
>>>>>>> ce/master
  groupsPath: '/api/:version/groups.json',
  groupPath: '/api/:version/groups/:id.json',
  namespacesPath: '/api/:version/namespaces.json',
  groupProjectsPath: '/api/:version/groups/:id/projects.json',
  projectsPath: '/api/:version/projects.json?simple=true',
  labelsPath: '/:namespace_path/:project_path/labels',
  licensePath: '/api/:version/templates/licenses/:key',
  gitignorePath: '/api/:version/templates/gitignores/:key',
  gitlabCiYmlPath: '/api/:version/templates/gitlab_ci_ymls/:key',
<<<<<<< HEAD
  ldapGroupsPath: '/api/:version/ldap/:provider/groups.json',
  dockerfilePath: '/api/:version/templates/dockerfiles/:key',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  group: function(group_id, callback) {
    var url = Api.buildUrl(Api.groupPath)
      .replace(':id', group_id);
    return $.ajax({
      url: url,
      dataType: 'json'
    }).done(function(group) {
      return callback(group);
    });
  },
  users: function(search, options, callback = $.noop) {
    var url = Api.buildUrl('/autocomplete/users.json');
    return $.ajax({
      url,
      data: $.extend({
        search,
        per_page: 20
      }, options),
      dataType: 'json'
    }).done(callback);
  },
  // Return groups list. Filtered by query
  groups: function(query, options, callback = $.noop) {
    var url = Api.buildUrl(Api.groupsPath);
=======
  dockerfilePath: '/api/:version/templates/dockerfiles/:key',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  usersPath: '/api/:version/users.json',

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
  groups(query, options, callback) {
    const url = Api.buildUrl(Api.groupsPath);
>>>>>>> ce/master
    return $.ajax({
      url,
      data: Object.assign({
        search: query,
        per_page: 20,
      }, options),
<<<<<<< HEAD
      dataType: 'json'
    }).done(function(groups) {
      return callback(groups);
    });
=======
      dataType: 'json',
    })
      .done(groups => callback(groups));
>>>>>>> ce/master
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
<<<<<<< HEAD
      dataType: 'json'
    }).done(function(namespaces) {
      return callback(namespaces);
    });
=======
      dataType: 'json',
    }).done(namespaces => callback(namespaces));
>>>>>>> ce/master
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
<<<<<<< HEAD
      dataType: 'json'
    }).done(function(projects) {
      return callback(projects);
    });
=======
      dataType: 'json',
    })
      .done(projects => callback(projects));
>>>>>>> ce/master
  },

  newLabel(namespacePath, projectPath, data, callback) {
    const url = Api.buildUrl(Api.labelsPath)
      .replace(':namespace_path', namespacePath)
      .replace(':project_path', projectPath);
    return $.ajax({
<<<<<<< HEAD
      url: url,
      type: 'POST',
      data: { 'label': data },
      dataType: 'json'
    }).done(function(label) {
      return callback(label);
    }).error(function(message) {
      return callback(message.responseJSON);
    });
=======
      url,
      type: 'POST',
      data: { label: data },
      dataType: 'json',
    })
      .done(label => callback(label))
      .error(message => callback(message.responseJSON));
>>>>>>> ce/master
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
<<<<<<< HEAD
      dataType: 'json'
    }).done(function(projects) {
      return callback(projects);
    });
=======
      dataType: 'json',
    })
      .done(projects => callback(projects));
>>>>>>> ce/master
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
      .error(callback);
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

  buildUrl(url) {
    let urlRoot = '';
    if (gon.relative_url_root != null) {
      urlRoot = gon.relative_url_root;
    }
<<<<<<< HEAD
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
      dataType: 'json'
    }).done(function(groups) {
      return callback(groups);
    });
  }
=======
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
>>>>>>> ce/master
};

export default Api;
