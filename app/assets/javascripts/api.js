import $ from 'jquery';
import axios from './lib/utils/axios_utils';

const Api = {
  groupsPath: '/api/:version/groups.json',
  groupPath: '/api/:version/groups/:id.json',
  namespacesPath: '/api/:version/namespaces.json',
  groupProjectsPath: '/api/:version/groups/:id/projects.json',
  projectsPath: '/api/:version/projects.json',
  projectPath: '/api/:version/projects/:id',
  projectLabelsPath: '/:namespace_path/:project_path/labels',
  groupLabelsPath: '/groups/:namespace_path/labels',
  licensePath: '/api/:version/templates/licenses/:key',
  gitignorePath: '/api/:version/templates/gitignores/:key',
  gitlabCiYmlPath: '/api/:version/templates/gitlab_ci_ymls/:key',
  dockerfilePath: '/api/:version/templates/dockerfiles/:key',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  usersPath: '/api/:version/users.json',
  commitPath: '/api/:version/projects/:id/repository/commits',
  branchSinglePath: '/api/:version/projects/:id/repository/branches/:branch',
  createBranchPath: '/api/:version/projects/:id/repository/branches',

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
    const defaults = {
      search: query,
      per_page: 20,
      simple: true,
    };

    if (gon.current_user_id) {
      defaults.membership = true;
    }

    return $.ajax({
      url,
      data: Object.assign(defaults, options),
      dataType: 'json',
    })
      .done(projects => callback(projects));
  },

  // Return single project
  project(projectPath) {
    const url = Api.buildUrl(Api.projectPath)
            .replace(':id', encodeURIComponent(projectPath));

    return axios.get(url);
  },

  newLabel(namespacePath, projectPath, data, callback) {
    let url;

    if (projectPath) {
      url = Api.buildUrl(Api.projectLabelsPath)
        .replace(':namespace_path', namespacePath)
        .replace(':project_path', projectPath);
    } else {
      url = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespacePath);
    }

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

  commitMultiple(id, data) {
    // see https://docs.gitlab.com/ce/api/commits.html#create-a-commit-with-multiple-files-and-actions
    const url = Api.buildUrl(Api.commitPath)
      .replace(':id', encodeURIComponent(id));
    return this.wrapAjaxCall({
      url,
      type: 'POST',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(data),
      dataType: 'json',
    });
  },

  branchSingle(id, branch) {
    const url = Api.buildUrl(Api.branchSinglePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':branch', branch);

    return this.wrapAjaxCall({
      url,
      type: 'GET',
      contentType: 'application/json; charset=utf-8',
      dataType: 'json',
    });
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
          if (jqXHR && jqXHR.responseJSON) error.responseJSON = jqXHR.responseJSON;
          reject(error);
        },
      );
    });
  },
};

export default Api;
