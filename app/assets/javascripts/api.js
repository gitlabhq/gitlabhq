import $ from 'jquery';
import _ from 'underscore';
import axios from './lib/utils/axios_utils';
import { joinPaths } from './lib/utils/url_utility';
import flash from '~/flash';
import { __ } from '~/locale';

const DEFAULT_PER_PAGE = 20;

const Api = {
  groupsPath: '/api/:version/groups.json',
  groupPath: '/api/:version/groups/:id',
  groupMembersPath: '/api/:version/groups/:id/members',
  subgroupsPath: '/api/:version/groups/:id/subgroups',
  namespacesPath: '/api/:version/namespaces.json',
  groupProjectsPath: '/api/:version/groups/:id/projects.json',
  projectsPath: '/api/:version/projects.json',
  projectPath: '/api/:version/projects/:id',
  forkedProjectsPath: '/api/:version/projects/:id/forks',
  projectLabelsPath: '/:namespace_path/:project_path/-/labels',
  projectUsersPath: '/api/:version/projects/:id/users',
  projectMergeRequestsPath: '/api/:version/projects/:id/merge_requests',
  projectMergeRequestPath: '/api/:version/projects/:id/merge_requests/:mrid',
  projectMergeRequestChangesPath: '/api/:version/projects/:id/merge_requests/:mrid/changes',
  projectMergeRequestVersionsPath: '/api/:version/projects/:id/merge_requests/:mrid/versions',
  projectRunnersPath: '/api/:version/projects/:id/runners',
  mergeRequestsPath: '/api/:version/merge_requests',
  groupLabelsPath: '/groups/:namespace_path/-/labels',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  projectTemplatePath: '/api/:version/projects/:id/templates/:type/:key',
  projectTemplatesPath: '/api/:version/projects/:id/templates/:type',
  userCountsPath: '/api/:version/user_counts',
  usersPath: '/api/:version/users.json',
  userPath: '/api/:version/users/:id',
  userStatusPath: '/api/:version/users/:id/status',
  userProjectsPath: '/api/:version/users/:id/projects',
  userPostStatusPath: '/api/:version/user/status',
  commitPath: '/api/:version/projects/:id/repository/commits',
  applySuggestionPath: '/api/:version/suggestions/:id/apply',
  commitPipelinesPath: '/:project_id/commit/:sha/pipelines',
  branchSinglePath: '/api/:version/projects/:id/repository/branches/:branch',
  createBranchPath: '/api/:version/projects/:id/repository/branches',
  releasesPath: '/api/:version/projects/:id/releases',
  releasePath: '/api/:version/projects/:id/releases/:tag_name',
  mergeRequestsPipeline: '/api/:version/projects/:id/merge_requests/:merge_request_iid/pipelines',
  adminStatisticsPath: 'api/:version/application/statistics',

  group(groupId, callback) {
    const url = Api.buildUrl(Api.groupPath).replace(':id', groupId);
    return axios.get(url).then(({ data }) => {
      callback(data);

      return data;
    });
  },

  groupMembers(id) {
    const url = Api.buildUrl(this.groupMembersPath).replace(':id', encodeURIComponent(id));

    return axios.get(url);
  },

  // Return groups list. Filtered by query
  groups(query, options, callback = $.noop) {
    const url = Api.buildUrl(Api.groupsPath);
    return axios
      .get(url, {
        params: Object.assign(
          {
            search: query,
            per_page: DEFAULT_PER_PAGE,
          },
          options,
        ),
      })
      .then(({ data }) => {
        callback(data);

        return data;
      });
  },

  groupLabels(namespace) {
    const url = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespace);
    return axios.get(url).then(({ data }) => data);
  },

  // Return namespaces list. Filtered by query
  namespaces(query, callback) {
    const url = Api.buildUrl(Api.namespacesPath);
    return axios
      .get(url, {
        params: {
          search: query,
          per_page: DEFAULT_PER_PAGE,
        },
      })
      .then(({ data }) => callback(data));
  },

  // Return projects list. Filtered by query
  projects(query, options, callback = _.noop) {
    const url = Api.buildUrl(Api.projectsPath);
    const defaults = {
      search: query,
      per_page: DEFAULT_PER_PAGE,
      simple: true,
    };

    if (gon.current_user_id) {
      defaults.membership = true;
    }

    return axios
      .get(url, {
        params: Object.assign(defaults, options),
      })
      .then(({ data, headers }) => {
        callback(data);
        return { data, headers };
      });
  },

  projectUsers(projectPath, query = '', options = {}) {
    const url = Api.buildUrl(this.projectUsersPath).replace(':id', encodeURIComponent(projectPath));

    return axios
      .get(url, {
        params: {
          search: query,
          per_page: DEFAULT_PER_PAGE,
          ...options,
        },
      })
      .then(({ data }) => data);
  },

  // Return single project
  project(projectPath) {
    const url = Api.buildUrl(Api.projectPath).replace(':id', encodeURIComponent(projectPath));

    return axios.get(url);
  },

  /**
   * Get all projects for a forked relationship to a specified project
   * @param {string} projectPath - Path or ID of a project
   * @param {Object} params - Get request parameters
   * @returns {Promise} - Request promise
   */
  projectForks(projectPath, params) {
    const url = Api.buildUrl(Api.forkedProjectsPath).replace(
      ':id',
      encodeURIComponent(projectPath),
    );

    return axios.get(url, { params });
  },

  /**
   * Get all Merge Requests for a project, eventually filtering based on
   * supplied parameters
   * @param projectPath
   * @param params
   * @returns {Promise}
   */
  projectMergeRequests(projectPath, params = {}) {
    const url = Api.buildUrl(Api.projectMergeRequestsPath).replace(
      ':id',
      encodeURIComponent(projectPath),
    );

    return axios.get(url, { params });
  },

  // Return Merge Request for project
  projectMergeRequest(projectPath, mergeRequestId, params = {}) {
    const url = Api.buildUrl(Api.projectMergeRequestPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':mrid', mergeRequestId);

    return axios.get(url, { params });
  },

  projectMergeRequestChanges(projectPath, mergeRequestId) {
    const url = Api.buildUrl(Api.projectMergeRequestChangesPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':mrid', mergeRequestId);

    return axios.get(url);
  },

  projectMergeRequestVersions(projectPath, mergeRequestId) {
    const url = Api.buildUrl(Api.projectMergeRequestVersionsPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':mrid', mergeRequestId);

    return axios.get(url);
  },

  projectRunners(projectPath, config = {}) {
    const url = Api.buildUrl(Api.projectRunnersPath).replace(
      ':id',
      encodeURIComponent(projectPath),
    );

    return axios.get(url, config);
  },

  mergeRequests(params = {}) {
    const url = Api.buildUrl(Api.mergeRequestsPath);

    return axios.get(url, { params });
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
  groupProjects(groupId, query, options, callback) {
    const url = Api.buildUrl(Api.groupProjectsPath).replace(':id', groupId);
    const defaults = {
      search: query,
      per_page: DEFAULT_PER_PAGE,
    };
    return axios
      .get(url, {
        params: Object.assign({}, defaults, options),
      })
      .then(({ data }) => callback(data))
      .catch(() => flash(__('Something went wrong while fetching projects')));
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

  applySuggestion(id) {
    const url = Api.buildUrl(Api.applySuggestionPath).replace(':id', encodeURIComponent(id));

    return axios.put(url);
  },

  commitPipelines(projectId, sha) {
    const encodedProjectId = projectId
      .split('/')
      .map(fragment => encodeURIComponent(fragment))
      .join('/');

    const url = Api.buildUrl(Api.commitPipelinesPath)
      .replace(':project_id', encodedProjectId)
      .replace(':sha', encodeURIComponent(sha));

    return axios.get(url);
  },

  branchSingle(id, branch) {
    const url = Api.buildUrl(Api.branchSinglePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':branch', encodeURIComponent(branch));

    return axios.get(url);
  },

  projectTemplate(id, type, key, options, callback) {
    const url = Api.buildUrl(this.projectTemplatePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':type', type)
      .replace(':key', encodeURIComponent(key));

    return axios.get(url, { params: options }).then(res => {
      if (callback) callback(res.data);

      return res;
    });
  },

  projectTemplates(id, type, params = {}, callback) {
    const url = Api.buildUrl(this.projectTemplatesPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':type', type);

    return axios.get(url, { params }).then(res => {
      if (callback) callback(res.data);

      return res;
    });
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
          per_page: DEFAULT_PER_PAGE,
        },
        options,
      ),
    });
  },

  user(id, options) {
    const url = Api.buildUrl(this.userPath).replace(':id', encodeURIComponent(id));
    return axios.get(url, {
      params: options,
    });
  },

  userCounts() {
    const url = Api.buildUrl(this.userCountsPath);
    return axios.get(url);
  },

  userStatus(id, options) {
    const url = Api.buildUrl(this.userStatusPath).replace(':id', encodeURIComponent(id));
    return axios.get(url, {
      params: options,
    });
  },

  userProjects(userId, query, options, callback) {
    const url = Api.buildUrl(Api.userProjectsPath).replace(':id', userId);
    const defaults = {
      search: query,
      per_page: DEFAULT_PER_PAGE,
    };
    return axios
      .get(url, {
        params: Object.assign({}, defaults, options),
      })
      .then(({ data }) => callback(data))
      .catch(() => flash(__('Something went wrong while fetching projects')));
  },

  branches(id, query = '', options = {}) {
    const url = Api.buildUrl(this.createBranchPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        search: query,
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  createBranch(id, { ref, branch }) {
    const url = Api.buildUrl(this.createBranchPath).replace(':id', encodeURIComponent(id));

    return axios.post(url, {
      ref,
      branch,
    });
  },

  postUserStatus({ emoji, message }) {
    const url = Api.buildUrl(this.userPostStatusPath);

    return axios.put(url, {
      emoji,
      message,
    });
  },

  postMergeRequestPipeline(id, { mergeRequestId }) {
    const url = Api.buildUrl(this.mergeRequestsPipeline)
      .replace(':id', encodeURIComponent(id))
      .replace(':merge_request_iid', mergeRequestId);

    return axios.post(url);
  },

  releases(id, options = {}) {
    const url = Api.buildUrl(this.releasesPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  release(projectPath, tagName) {
    const url = Api.buildUrl(this.releasePath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':tag_name', encodeURIComponent(tagName));

    return axios.get(url);
  },

  updateRelease(projectPath, tagName, release) {
    const url = Api.buildUrl(this.releasePath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':tag_name', encodeURIComponent(tagName));

    return axios.put(url, release);
  },

  adminStatistics() {
    const url = Api.buildUrl(this.adminStatisticsPath);
    return axios.get(url);
  },

  buildUrl(url) {
    return joinPaths(gon.relative_url_root || '', url.replace(':version', gon.api_version));
  },
};

export default Api;
