import $ from 'jquery';
import _ from 'underscore';
import axios from './lib/utils/axios_utils';

const Api = {
  groupsPath: '/api/:version/groups.json',
  groupPath: '/api/:version/groups/:id',
  namespacesPath: '/api/:version/namespaces.json',
  groupProjectsPath: '/api/:version/groups/:id/projects.json',
  projectsPath: '/api/:version/projects.json',
  projectPath: '/api/:version/projects/:id',
  projectLabelsPath: '/:namespace_path/:project_path/labels',
  mergeRequestPath: '/api/:version/projects/:id/merge_requests/:mrid',
  mergeRequestChangesPath: '/api/:version/projects/:id/merge_requests/:mrid/changes',
  mergeRequestVersionsPath: '/api/:version/projects/:id/merge_requests/:mrid/versions',
  groupLabelsPath: '/groups/:namespace_path/-/labels',
  licensePath: '/api/:version/templates/licenses/:key',
  gitignorePath: '/api/:version/templates/gitignores/:key',
  gitlabCiYmlPath: '/api/:version/templates/gitlab_ci_ymls/:key',
  ldapGroupsPath: '/api/:version/ldap/:provider/groups.json',
  dockerfilePath: '/api/:version/templates/dockerfiles/:key',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  usersPath: '/api/:version/users.json',
  commitPath: '/api/:version/projects/:id/repository/commits',
  branchSinglePath: '/api/:version/projects/:id/repository/branches/:branch',
  createBranchPath: '/api/:version/projects/:id/repository/branches',
  geoNodesPath: '/api/:version/geo_nodes',

  group(groupId, callback) {
    const url = Api.buildUrl(Api.groupPath).replace(':id', groupId);
    return axios.get(url).then(({ data }) => {
      callback(data);

      return data;
    });
  },

  // Return groups list. Filtered by query
  groups(query, options, callback = $.noop) {
    const url = Api.buildUrl(Api.groupsPath);
    return axios
      .get(url, {
        params: Object.assign(
          {
            search: query,
            per_page: 20,
          },
          options,
        ),
      })
      .then(({ data }) => {
        callback(data);

        return data;
      });
  },

  // Return namespaces list. Filtered by query
  namespaces(query, callback) {
    const url = Api.buildUrl(Api.namespacesPath);
    return axios
      .get(url, {
        params: {
          search: query,
          per_page: 20,
        },
      })
      .then(({ data }) => callback(data));
  },

  // Return projects list. Filtered by query
  projects(query, options, callback = _.noop) {
    const url = Api.buildUrl(Api.projectsPath);
    const defaults = {
      search: query,
      per_page: 20,
      simple: true,
    };

    if (gon.current_user_id) {
      defaults.membership = true;
    }

    return axios
      .get(url, {
        params: Object.assign(defaults, options),
      })
      .then(({ data }) => {
        callback(data);

        return data;
      });
  },

  // Return single project
  project(projectPath) {
    const url = Api.buildUrl(Api.projectPath).replace(':id', encodeURIComponent(projectPath));

    return axios.get(url);
  },

  // Return Merge Request for project
  mergeRequest(projectPath, mergeRequestId) {
    const url = Api.buildUrl(Api.mergeRequestPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':mrid', mergeRequestId);

    return axios.get(url);
  },

  mergeRequestChanges(projectPath, mergeRequestId) {
    const url = Api.buildUrl(Api.mergeRequestChangesPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':mrid', mergeRequestId);

    return axios.get(url);
  },

  mergeRequestVersions(projectPath, mergeRequestId) {
    const url = Api.buildUrl(Api.mergeRequestVersionsPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':mrid', mergeRequestId);

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

    return axios
      .post(url, {
        label: data,
      })
      .then(res => callback(res.data))
      .catch(e => callback(e.response.data));
  },

  // Return group projects list. Filtered by query
  groupProjects(groupId, query, callback) {
    const url = Api.buildUrl(Api.groupProjectsPath).replace(':id', groupId);
    return axios
      .get(url, {
        params: {
          search: query,
          per_page: 20,
        },
      })
      .then(({ data }) => callback(data));
  },

  commitMultiple(id, data) {
    // see https://docs.gitlab.com/ce/api/commits.html#create-a-commit-with-multiple-files-and-actions
    const url = Api.buildUrl(Api.commitPath).replace(':id', encodeURIComponent(id));
    return axios.post(url, JSON.stringify(data), {
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    });
  },

  branchSingle(id, branch) {
    const url = Api.buildUrl(Api.branchSinglePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':branch', encodeURIComponent(branch));

    return axios.get(url);
  },

  // Return text for a specific license
  licenseText(key, data, callback) {
    const url = Api.buildUrl(Api.licensePath).replace(':key', key);
    return axios
      .get(url, {
        params: data,
      })
      .then(res => callback(res.data));
  },

  gitignoreText(key, callback) {
    const url = Api.buildUrl(Api.gitignorePath).replace(':key', key);
    return axios.get(url).then(({ data }) => callback(data));
  },

  gitlabCiYml(key, callback) {
    const url = Api.buildUrl(Api.gitlabCiYmlPath).replace(':key', key);
    return axios.get(url).then(({ data }) => callback(data));
  },

  dockerfileYml(key, callback) {
    const url = Api.buildUrl(Api.dockerfilePath).replace(':key', key);
    return axios.get(url).then(({ data }) => callback(data));
  },

  issueTemplate(namespacePath, projectPath, key, type, callback) {
    const url = Api.buildUrl(Api.issuableTemplatePath)
      .replace(':key', encodeURIComponent(key))
      .replace(':type', type)
      .replace(':project_path', projectPath)
      .replace(':namespace_path', namespacePath);
    return axios
      .get(url)
      .then(({ data }) => callback(null, data))
      .catch(callback);
  },

  users(query, options) {
    const url = Api.buildUrl(this.usersPath);
    return axios.get(url, {
      params: Object.assign(
        {
          search: query,
          per_page: 20,
        },
        options,
      ),
    });
  },

  approverUsers(search, options, callback = $.noop) {
    const url = Api.buildUrl('/autocomplete/users.json');
    return axios.get(url, {
      params: Object.assign({
        search,
        per_page: 20,
      }, options),
    }).then(({ data }) => {
      callback(data);

      return data;
    });
  },

  ldap_groups(query, provider, callback) {
    const url = Api.buildUrl(this.ldapGroupsPath).replace(':provider', provider);
    return axios.get(url, {
      params: {
        search: query,
        per_page: 20,
        active: true,
      },
    }).then(({ data }) => {
      callback(data);

      return data;
    });
  },

  buildUrl(url) {
    let urlRoot = '';
    if (gon.relative_url_root != null) {
      urlRoot = gon.relative_url_root;
    }
    return urlRoot + url.replace(':version', gon.api_version);
  },
};

export default Api;
