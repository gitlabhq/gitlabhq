import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { validateAdditionalProperties } from '~/tracking/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from './lib/utils/axios_utils';
import { joinPaths } from './lib/utils/url_utility';

export const DEFAULT_PER_PAGE = 20;

/**
 * Slow deprecation Notice: Please rather use for new calls
 * or during refactors /rest_api as this is doing named exports
 * which support treeshaking
 */

const Api = {
  DEFAULT_PER_PAGE,
  groupsPath: '/api/:version/groups.json',
  groupPath: '/api/:version/groups/:id',
  groupMembersPath: '/api/:version/groups/:id/members',
  groupMilestonesPath: '/api/:version/groups/:id/milestones',
  subgroupsPath: '/api/:version/groups/:id/subgroups',
  descendantGroupsPath: '/api/:version/groups/:id/descendant_groups',
  namespacesPath: '/api/:version/namespaces.json',
  groupInvitationsPath: '/api/:version/groups/:id/invitations',
  groupPackagesPath: '/api/:version/groups/:id/packages',
  projectPackagesPath: '/api/:version/projects/:id/packages',
  projectPackagePath: '/api/:version/projects/:id/packages/:package_id',
  projectPackageFilePath:
    '/api/:version/projects/:id/packages/:package_id/package_files/:package_file_id',
  projectGroupsPath: '/api/:version/projects/:id/groups.json',
  groupProjectsPath: '/api/:version/groups/:id/projects.json',
  groupSharePath: '/api/:version/groups/:id/share',
  projectsPath: '/api/:version/projects.json',
  projectPath: '/api/:version/projects/:id',
  forkedProjectsPath: '/api/:version/projects/:id/forks',
  projectLabelsPath: '/:namespace_path/:project_path/-/labels',
  projectFileSchemaPath: '/:namespace_path/:project_path/-/schema/:ref/:filename',
  projectUsersPath: '/api/:version/projects/:id/users',
  projectInvitationsPath: '/api/:version/projects/:id/invitations',
  projectMembersPath: '/api/:version/projects/:id/members',
  projectMergeRequestsPath: '/api/:version/projects/:id/merge_requests',
  projectMergeRequestPath: '/api/:version/projects/:id/merge_requests/:mrid',
  projectMergeRequestChangesPath: '/api/:version/projects/:id/merge_requests/:mrid/changes',
  projectMergeRequestVersionsPath: '/api/:version/projects/:id/merge_requests/:mrid/versions',
  projectRunnersPath: '/api/:version/projects/:id/runners',
  projectProtectedBranchesPath: '/api/:version/projects/:id/protected_branches',
  projectProtectedBranchesNamePath: '/api/:version/projects/:id/protected_branches/:name',
  projectSearchPath: '/api/:version/projects/:id/search',
  projectSharePath: '/api/:version/projects/:id/share',
  projectMilestonesPath: '/api/:version/projects/:id/milestones',
  projectIssuePath: '/api/:version/projects/:id/issues/:issue_iid',
  projectCreateIssuePath: '/api/:version/projects/:id/issues',
  mergeRequestsPath: '/api/:version/merge_requests',
  groupLabelsPath: '/api/:version/groups/:namespace_path/labels',
  issuableTemplatePath: '/:namespace_path/:project_path/templates/:type/:key',
  issuableTemplatesPath: '/:namespace_path/:project_path/templates/:type',
  projectTemplatePath: '/api/:version/projects/:id/templates/:type/:key',
  projectTemplatesPath: '/api/:version/projects/:id/templates/:type',
  userCountsPath: '/api/:version/user_counts',
  usersPath: '/api/:version/users.json',
  userPath: '/api/:version/users/:id',
  userStatusPath: '/api/:version/users/:id/status',
  userProjectsPath: '/api/:version/users/:id/projects',
  userPostStatusPath: '/api/:version/user/status',
  commitPath: '/api/:version/projects/:id/repository/commits/:sha',
  commitsPath: '/api/:version/projects/:id/repository/commits',
  applySuggestionPath: '/api/:version/suggestions/:id/apply',
  applySuggestionBatchPath: '/api/:version/suggestions/batch_apply',
  commitPipelinesPath: '/:project_id/commit/:sha/pipelines',
  branchSinglePath: '/api/:version/projects/:id/repository/branches/:branch',
  createBranchPath: '/api/:version/projects/:id/repository/branches',
  releasesPath: '/api/:version/projects/:id/releases',
  releasePath: '/api/:version/projects/:id/releases/:tag_name',
  releaseLinksPath: '/api/:version/projects/:id/releases/:tag_name/assets/links',
  releaseLinkPath: '/api/:version/projects/:id/releases/:tag_name/assets/links/:link_id',
  mergeRequestsPipeline: '/api/:version/projects/:id/merge_requests/:merge_request_iid/pipelines',
  adminStatisticsPath: '/api/:version/application/statistics',
  pipelineSinglePath: '/api/:version/projects/:id/pipelines/:pipeline_id',
  pipelinesPath: '/api/:version/projects/:id/pipelines/',
  createPipelinePath: '/api/:version/projects/:id/pipeline',
  environmentsPath: '/api/:version/projects/:id/environments',
  contextCommitsPath:
    '/api/:version/projects/:id/merge_requests/:merge_request_iid/context_commits',
  rawFilePath: '/api/:version/projects/:id/repository/files/:path/raw',
  issuePath: '/api/:version/projects/:id/issues/:issue_iid',
  tagsPath: '/api/:version/projects/:id/repository/tags',
  freezePeriodsPath: '/api/:version/projects/:id/freeze_periods',
  freezePeriodPath: '/api/:version/projects/:id/freeze_periods/:freeze_period_id',
  serviceDataIncrementCounterPath: '/api/:version/usage_data/increment_counter',
  serviceDataInternalEventPath: '/api/:version/usage_data/track_event',
  serviceDataIncrementUniqueUsersPath: '/api/:version/usage_data/increment_unique_users',
  featureFlagUserLists: '/api/:version/projects/:id/feature_flags_user_lists',
  featureFlagUserList: '/api/:version/projects/:id/feature_flags_user_lists/:list_iid',
  containerRegistryDetailsPath: '/api/:version/registry/repositories/:id/',
  projectNotificationSettingsPath: '/api/:version/projects/:id/notification_settings',
  groupNotificationSettingsPath: '/api/:version/groups/:id/notification_settings',
  notificationSettingsPath: '/api/:version/notification_settings',
  deployKeysPath: '/api/:version/deploy_keys',
  secureFilePath: '/api/:version/projects/:project_id/secure_files/:secure_file_id',
  secureFilesPath: '/api/:version/projects/:project_id/secure_files',
  markdownPath: '/api/:version/markdown',

  group(groupId, callback = () => {}) {
    const url = Api.buildUrl(Api.groupPath).replace(':id', groupId);
    return axios.get(url).then(({ data }) => {
      callback(data);

      return data;
    });
  },

  groupPackages(id, options = {}) {
    const url = Api.buildUrl(this.groupPackagesPath).replace(':id', id);
    return axios.get(url, options);
  },

  projectPackages(id, options = {}) {
    const url = Api.buildUrl(this.projectPackagesPath).replace(':id', id);
    return axios.get(url, options);
  },

  buildProjectPackageUrl(projectId, packageId) {
    return Api.buildUrl(this.projectPackagePath)
      .replace(':id', projectId)
      .replace(':package_id', packageId);
  },

  projectPackage(projectId, packageId) {
    const url = this.buildProjectPackageUrl(projectId, packageId);
    return axios.get(url);
  },

  projectGroups(id, options) {
    const url = Api.buildUrl(this.projectGroupsPath).replace(':id', encodeURIComponent(id));

    return axios
      .get(url, {
        params: {
          ...options,
        },
      })
      .then(({ data }) => {
        return data;
      });
  },

  deleteProjectPackage(projectId, packageId) {
    const url = this.buildProjectPackageUrl(projectId, packageId);
    return axios.delete(url);
  },

  deleteProjectPackageFile(projectId, packageId, fileId) {
    const url = Api.buildUrl(this.projectPackageFilePath)
      .replace(':id', projectId)
      .replace(':package_id', packageId)
      .replace(':package_file_id', fileId);

    return axios.delete(url);
  },

  containerRegistryDetails(registryId, options = {}) {
    const url = Api.buildUrl(this.containerRegistryDetailsPath).replace(':id', registryId);
    return axios.get(url, options);
  },

  groupMembers(id, options) {
    const url = Api.buildUrl(this.groupMembersPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  groupSubgroups(id, options) {
    const url = Api.buildUrl(this.subgroupsPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  inviteGroupMembers(id, data) {
    const url = Api.buildUrl(this.groupInvitationsPath).replace(':id', encodeURIComponent(id));

    return axios.post(url, data);
  },

  groupMilestones(id, options) {
    const url = Api.buildUrl(this.groupMilestonesPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  /**
   * @deprecated This method will be removed soon. Use the
   * `getGroups` method in `~/rest_api` instead.
   */
  groups(query, options, callback = () => {}) {
    const url = Api.buildUrl(Api.groupsPath);
    return axios
      .get(url, {
        params: {
          search: query,
          per_page: DEFAULT_PER_PAGE,
          ...options,
        },
      })
      .then(({ data }) => {
        callback(data);

        return data;
      });
  },

  groupLabels(namespace, options = {}) {
    const url = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespace);
    return axios.get(url, options).then(({ data }) => data);
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

  /**
   * @deprecated This method will be removed soon. Use the
   * `getProjects` method in `~/rest_api` instead.
   */
  projects(query, options, callback = () => {}) {
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
        params: { ...defaults, ...options },
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

  inviteProjectMembers(id, data) {
    const url = Api.buildUrl(this.projectInvitationsPath).replace(':id', encodeURIComponent(id));

    return axios.post(url, data);
  },

  // Return single project
  project(projectPath) {
    const url = Api.buildUrl(Api.projectPath).replace(':id', encodeURIComponent(projectPath));

    return axios.get(url);
  },

  // Update a single project
  updateProject(projectPath, data) {
    const url = Api.buildUrl(Api.projectPath).replace(':id', encodeURIComponent(projectPath));
    return axios.put(url, data);
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
   * Get all merge requests for a project, eventually filtering based on
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

  createProjectMergeRequest(projectPath, options) {
    const url = Api.buildUrl(Api.projectMergeRequestsPath).replace(
      ':id',
      encodeURIComponent(projectPath),
    );

    return axios.post(url, options);
  },

  // Return merge request for project
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

  projectProtectedBranches(id, query = '') {
    const url = Api.buildUrl(Api.projectProtectedBranchesPath).replace(
      ':id',
      encodeURIComponent(id),
    );

    return axios
      .get(url, {
        params: {
          search: query,
          per_page: DEFAULT_PER_PAGE,
        },
      })
      .then(({ data }) => data);
  },

  projectProtectedBranch(id, branchName) {
    const url = Api.buildUrl(Api.projectProtectedBranchesNamePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':name', branchName);

    return axios.get(url).then(({ data }) => data);
  },

  projectSearch(id, options = {}) {
    const url = Api.buildUrl(Api.projectSearchPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        search: options.search,
        scope: options.scope,
      },
    });
  },

  projectShareWithGroup(id, options = {}) {
    const url = Api.buildUrl(Api.projectSharePath).replace(':id', encodeURIComponent(id));

    return axios.post(url, {
      expires_at: options.expires_at,
      group_access: options.group_access,
      group_id: options.group_id,
      member_role_id: options.member_role_id,
    });
  },

  projectMilestones(id, params = {}) {
    const url = Api.buildUrl(Api.projectMilestonesPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params,
    });
  },

  addProjectIssueAsTodo(projectId, issueIid) {
    const url = Api.buildUrl(Api.projectIssuePath)
      .replace(':id', encodeURIComponent(projectId))
      .replace(':issue_iid', encodeURIComponent(issueIid));

    return axios.post(`${url}/todo`);
  },

  mergeRequests(params = {}) {
    const url = Api.buildUrl(Api.mergeRequestsPath);

    return axios.get(url, { params });
  },

  // eslint-disable-next-line max-params
  newLabel(namespacePath, projectPath, data, callback) {
    let url;
    let payload;

    if (projectPath) {
      url = Api.buildUrl(Api.projectLabelsPath)
        .replace(':namespace_path', namespacePath)
        .replace(':project_path', projectPath);
      payload = {
        label: data,
      };
    } else {
      url = Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespacePath);

      // groupLabelsPath uses public API which accepts
      // `name` and `color` props.
      payload = {
        name: data.title,
        color: data.color,
      };
    }

    return axios
      .post(url, {
        ...payload,
      })
      .then((res) => callback(res.data))
      .catch((e) => callback(e.response.data));
  },

  // Return group projects list. Filtered by query
  // eslint-disable-next-line max-params
  groupProjects(groupId, query, options, callback = () => {}) {
    const url = Api.buildUrl(Api.groupProjectsPath).replace(':id', groupId);
    const defaults = {
      search: query,
      per_page: DEFAULT_PER_PAGE,
    };
    return axios
      .get(url, {
        params: { ...defaults, ...options },
      })
      .then(({ data, headers }) => {
        callback(data);
        return { data, headers };
      });
  },

  groupShareWithGroup(id, options = {}) {
    const url = Api.buildUrl(Api.groupSharePath).replace(':id', encodeURIComponent(id));

    return axios.post(url, {
      expires_at: options.expires_at,
      group_access: options.group_access,
      group_id: options.group_id,
      member_role_id: options.member_role_id,
    });
  },

  commit(id, sha, params = {}) {
    const url = Api.buildUrl(this.commitPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':sha', encodeURIComponent(sha));

    return axios.get(url, { params });
  },

  commitMultiple(id, data) {
    // see https://docs.gitlab.com/ee/api/commits.html#create-a-commit-with-multiple-files-and-actions
    const url = Api.buildUrl(Api.commitsPath).replace(':id', encodeURIComponent(id));
    return axios.post(url, JSON.stringify(data), {
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    });
  },

  applySuggestion(id, message = '') {
    const url = Api.buildUrl(Api.applySuggestionPath).replace(':id', encodeURIComponent(id));
    const params = { commit_message: message };

    return axios.put(url, params);
  },

  applySuggestionBatch(ids, message) {
    const url = Api.buildUrl(Api.applySuggestionBatchPath);

    return axios.put(url, { ids, commit_message: message });
  },

  commitPipelines(projectId, sha) {
    const encodedProjectId = projectId
      .split('/')
      .map((fragment) => encodeURIComponent(fragment))
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

  // eslint-disable-next-line max-params
  projectTemplate(id, type, key, options, callback) {
    const url = Api.buildUrl(this.projectTemplatePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':type', type)
      .replace(':key', encodeURIComponent(key));

    return axios.get(url, { params: options }).then((res) => {
      if (callback) callback(res.data);

      return res;
    });
  },

  // eslint-disable-next-line max-params
  projectTemplates(id, type, params = {}, callback) {
    const url = Api.buildUrl(this.projectTemplatesPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':type', type);

    return axios.get(url, { params }).then((res) => {
      if (callback) callback(res.data);

      return res;
    });
  },

  // eslint-disable-next-line max-params
  issueTemplate(namespacePath, projectPath, key, type, callback) {
    const url = this.buildIssueTemplateUrl(
      Api.issuableTemplatePath,
      type,
      projectPath,
      namespacePath,
    ).replace(':key', encodeURIComponent(key));
    return axios
      .get(url)
      .then(({ data }) => callback(null, data))
      .catch(callback);
  },

  // eslint-disable-next-line max-params
  issueTemplates(namespacePath, projectPath, type, callback) {
    const url = this.buildIssueTemplateUrl(
      Api.issuableTemplatesPath,
      type,
      projectPath,
      namespacePath,
    );
    return axios
      .get(url)
      .then(({ data }) => callback(null, data))
      .catch(callback);
  },

  // eslint-disable-next-line max-params
  buildIssueTemplateUrl(path, type, projectPath, namespacePath) {
    return Api.buildUrl(path)
      .replace(':type', type)
      .replace(':project_path', projectPath)
      .replace(':namespace_path', namespacePath);
  },

  /**
   * @deprecated This method will be removed soon. Use the
   * `getUsers` method in `~/rest_api` instead.
   */
  users(query, options) {
    const url = Api.buildUrl(this.usersPath);
    return axios.get(url, {
      params: {
        search: query,
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  /**
   * @deprecated This method will be removed soon. Use the
   * `getUser` method in `~/rest_api` instead.
   */
  user(id, options) {
    const url = Api.buildUrl(this.userPath).replace(':id', encodeURIComponent(id));
    return axios.get(url, {
      params: options,
    });
  },

  /**
   * @deprecated This method will be removed soon. Use the
   * `getUserCounts` method in `~/rest_api` instead.
   */
  userCounts() {
    const url = Api.buildUrl(this.userCountsPath);
    return axios.get(url);
  },

  /**
   * @deprecated This method will be removed soon. Use the
   * `getUserStatus` method in `~/rest_api` instead.
   */
  userStatus(id, options) {
    const url = Api.buildUrl(this.userStatusPath).replace(':id', encodeURIComponent(id));
    return axios.get(url, {
      params: options,
    });
  },

  /**
   * @deprecated This method will be removed soon. Use the
   * `getUserProjects` method in `~/rest_api` instead.
   */
  // eslint-disable-next-line max-params
  userProjects(userId, query, options, callback) {
    const url = Api.buildUrl(Api.userProjectsPath).replace(':id', userId);
    const defaults = {
      search: query,
      per_page: DEFAULT_PER_PAGE,
    };
    return axios
      .get(url, {
        params: { ...defaults, ...options },
      })
      .then(({ data }) => callback(data))
      .catch(() =>
        createAlert({
          message: __('Something went wrong while fetching projects'),
        }),
      );
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

  /**
   * @deprecated This method will be removed soon. Use the
   * `updateUserStatus` method in `~/rest_api` instead.
   */
  postUserStatus({ emoji, message, availability }) {
    const url = Api.buildUrl(this.userPostStatusPath);

    return axios.put(url, {
      emoji,
      message,
      availability,
    });
  },

  postMergeRequestPipeline(id, { mergeRequestId }) {
    const url = Api.buildUrl(this.mergeRequestsPipeline)
      .replace(':id', encodeURIComponent(id))
      .replace(':merge_request_iid', mergeRequestId);

    const params = {
      async: true,
    };

    return axios.post(url, params);
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

  createRelease(projectPath, release) {
    const url = Api.buildUrl(this.releasesPath).replace(':id', encodeURIComponent(projectPath));

    return axios.post(url, release);
  },

  updateRelease(projectPath, tagName, release) {
    const url = Api.buildUrl(this.releasePath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':tag_name', encodeURIComponent(tagName));

    return axios.put(url, release);
  },

  createReleaseLink(projectPath, tagName, link) {
    const url = Api.buildUrl(this.releaseLinksPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':tag_name', encodeURIComponent(tagName));

    return axios.post(url, link);
  },

  deleteReleaseLink(projectPath, tagName, linkId) {
    const url = Api.buildUrl(this.releaseLinkPath)
      .replace(':id', encodeURIComponent(projectPath))
      .replace(':tag_name', encodeURIComponent(tagName))
      .replace(':link_id', encodeURIComponent(linkId));

    return axios.delete(url);
  },

  adminStatistics() {
    const url = Api.buildUrl(this.adminStatisticsPath);
    return axios.get(url);
  },

  pipelineSingle(id, pipelineId) {
    const url = Api.buildUrl(this.pipelineSinglePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':pipeline_id', encodeURIComponent(pipelineId));

    return axios.get(url);
  },

  // Return all pipelines for a project or filter by query params
  pipelines(id, options = {}) {
    const url = Api.buildUrl(this.pipelinesPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: options,
    });
  },

  createPipeline(id, data) {
    const url = Api.buildUrl(this.createPipelinePath).replace(':id', encodeURIComponent(id));

    return axios.post(url, data, {
      headers: {
        'Content-Type': 'application/json',
      },
    });
  },

  environments(id) {
    const url = Api.buildUrl(this.environmentsPath).replace(':id', encodeURIComponent(id));
    return axios.get(url);
  },

  createContextCommits(id, mergeRequestIid, data) {
    const url = Api.buildUrl(this.contextCommitsPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':merge_request_iid', mergeRequestIid);

    return axios.post(url, data);
  },

  allContextCommits(id, mergeRequestIid) {
    const url = Api.buildUrl(this.contextCommitsPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':merge_request_iid', mergeRequestIid);

    return axios.get(url);
  },

  removeContextCommits(id, mergeRequestIid, data) {
    const url = Api.buildUrl(this.contextCommitsPath)
      .replace(':id', id)
      .replace(':merge_request_iid', mergeRequestIid);

    return axios.delete(url, { data });
  },

  // eslint-disable-next-line max-params
  getRawFile(id, path, params = {}, options = {}) {
    const url = Api.buildUrl(this.rawFilePath)
      .replace(':id', encodeURIComponent(id))
      .replace(':path', encodeURIComponent(path));

    return axios.get(url, { params, ...options });
  },

  updateIssue(project, issue, data = {}) {
    const url = Api.buildUrl(Api.issuePath)
      .replace(':id', encodeURIComponent(project))
      .replace(':issue_iid', encodeURIComponent(issue));

    return axios.put(url, data);
  },

  updateMergeRequest(project, mergeRequest, data = {}) {
    const url = Api.buildUrl(Api.projectMergeRequestPath)
      .replace(':id', encodeURIComponent(project))
      .replace(':mrid', encodeURIComponent(mergeRequest));

    return axios.put(url, data);
  },

  tags(id, query = '', options = {}) {
    const url = Api.buildUrl(this.tagsPath).replace(':id', encodeURIComponent(id));

    return axios.get(url, {
      params: {
        search: query,
        per_page: DEFAULT_PER_PAGE,
        ...options,
      },
    });
  },

  tag(id, tagName) {
    const url = Api.buildUrl(this.tagPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':tag_name', encodeURIComponent(tagName));

    return axios.get(url);
  },

  freezePeriods(id) {
    const url = Api.buildUrl(this.freezePeriodsPath).replace(':id', encodeURIComponent(id));

    return axios.get(url);
  },

  createFreezePeriod(id, freezePeriod = {}) {
    const url = Api.buildUrl(this.freezePeriodsPath).replace(':id', encodeURIComponent(id));

    return axios.post(url, freezePeriod);
  },

  updateFreezePeriod(id, freezePeriod = {}) {
    const url = Api.buildUrl(this.freezePeriodPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':freeze_period_id', encodeURIComponent(freezePeriod.id));

    return axios.put(url, freezePeriod);
  },

  deleteFreezePeriod(id, freezePeriodId) {
    const url = Api.buildUrl(this.freezePeriodPath)
      .replace(':id', encodeURIComponent(id))
      .replace(':freeze_period_id', encodeURIComponent(freezePeriodId));

    return axios.delete(url);
  },

  trackRedisCounterEvent(event) {
    const url = Api.buildUrl(this.serviceDataIncrementCounterPath);
    const headers = {
      'Content-Type': 'application/json',
    };

    return axios.post(url, { event }, { headers });
  },

  trackRedisHllUserEvent(event) {
    if (!gon.current_user_id) {
      return null;
    }

    const url = Api.buildUrl(this.serviceDataIncrementUniqueUsersPath);
    const headers = {
      'Content-Type': 'application/json',
    };

    return axios.post(url, { event }, { headers });
  },

  trackInternalEvent(event, additionalProperties = {}) {
    if (!gon.current_user_id) {
      return null;
    }
    validateAdditionalProperties(additionalProperties);
    const url = Api.buildUrl(this.serviceDataInternalEventPath);
    const headers = {
      'Content-Type': 'application/json',
    };

    const { data = {} } = { ...window.gl?.snowplowStandardContext };
    const { project_id, namespace_id } = data;
    return axios
      .post(
        url,
        { event, project_id, namespace_id, additional_properties: additionalProperties },
        { headers },
      )
      .catch((error) => {
        Sentry.captureException(error);
      });
  },

  buildUrl(url) {
    return joinPaths(gon.relative_url_root || '', url.replace(':version', gon.api_version));
  },

  fetchFeatureFlagUserLists(id, page) {
    const url = Api.buildUrl(this.featureFlagUserLists).replace(':id', id);

    return axios.get(url, { params: { page } });
  },

  searchFeatureFlagUserLists(id, search) {
    const url = Api.buildUrl(this.featureFlagUserLists).replace(':id', id);

    return axios.get(url, { params: { search } });
  },

  createFeatureFlagUserList(id, list) {
    const url = Api.buildUrl(this.featureFlagUserLists).replace(':id', id);

    return axios.post(url, list);
  },

  fetchFeatureFlagUserList(id, listIid) {
    const url = Api.buildUrl(this.featureFlagUserList)
      .replace(':id', id)
      .replace(':list_iid', listIid);

    return axios.get(url);
  },

  updateFeatureFlagUserList(id, list) {
    const url = Api.buildUrl(this.featureFlagUserList)
      .replace(':id', id)
      .replace(':list_iid', list.iid);

    return axios.put(url, list);
  },

  deleteFeatureFlagUserList(id, listIid) {
    const url = Api.buildUrl(this.featureFlagUserList)
      .replace(':id', id)
      .replace(':list_iid', listIid);

    return axios.delete(url);
  },

  deployKeys(params = {}) {
    const url = Api.buildUrl(this.deployKeysPath);

    return axios.get(url, { params: { per_page: DEFAULT_PER_PAGE, ...params } });
  },

  // TODO: replace this when GraphQL support has been added https://gitlab.com/gitlab-org/gitlab/-/issues/352184
  projectSecureFiles(projectId, options = {}) {
    const url = Api.buildUrl(this.secureFilesPath).replace(':project_id', projectId);

    return axios.get(url, { params: { per_page: DEFAULT_PER_PAGE, ...options } });
  },

  uploadProjectSecureFile(projectId, fileData) {
    const url = Api.buildUrl(this.secureFilesPath).replace(':project_id', projectId);

    const headers = { 'Content-Type': 'multipart/form-data' };

    return axios.post(url, fileData, { headers });
  },

  deleteProjectSecureFile(projectId, secureFileId) {
    const url = Api.buildUrl(this.secureFilePath)
      .replace(':project_id', projectId)
      .replace(':secure_file_id', secureFileId);

    return axios.delete(url);
  },

  async updateNotificationSettings(projectId, groupId, data = {}) {
    let url = Api.buildUrl(this.notificationSettingsPath);

    if (projectId) {
      url = Api.buildUrl(this.projectNotificationSettingsPath).replace(':id', projectId);
    } else if (groupId) {
      url = Api.buildUrl(this.groupNotificationSettingsPath).replace(':id', groupId);
    }

    const result = await axios.put(url, data);

    return result;
  },

  async getNotificationSettings(projectId, groupId) {
    let url = Api.buildUrl(this.notificationSettingsPath);

    if (projectId) {
      url = Api.buildUrl(this.projectNotificationSettingsPath).replace(':id', projectId);
    } else if (groupId) {
      url = Api.buildUrl(this.groupNotificationSettingsPath).replace(':id', groupId);
    }

    const result = await axios.get(url);

    return result;
  },

  markdown(data = {}) {
    const url = Api.buildUrl(this.markdownPath);

    return axios.post(url, data);
  },
};

export default Api;
