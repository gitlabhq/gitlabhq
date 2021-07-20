import getIdeProject from 'ee_else_ce/ide/queries/get_ide_project.query.graphql';
import Api from '~/api';
import dismissUserCallout from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import axios from '~/lib/utils/axios_utils';
import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import ciConfig from '~/pipeline_editor/graphql/queries/ci_config.graphql';
import { query, mutate } from './gql';

const fetchApiProjectData = (projectPath) => Api.project(projectPath).then(({ data }) => data);

const fetchGqlProjectData = (projectPath) =>
  query({
    query: getIdeProject,
    variables: { projectPath },
  }).then(({ data }) => data.project);

export default {
  getFileData(endpoint) {
    return axios.get(endpoint, {
      params: { format: 'json', viewer: 'none' },
    });
  },
  getRawFileData(file) {
    if (file.tempFile && !file.prevPath) {
      return Promise.resolve(file.content);
    }

    if (file.raw || !file.rawPath) {
      return Promise.resolve(file.raw);
    }

    const options = file.binary ? { responseType: 'arraybuffer' } : {};

    return axios
      .get(file.rawPath, {
        transformResponse: [(f) => f],
        ...options,
      })
      .then(({ data }) => data);
  },
  getBaseRawFileData(file, projectId, ref) {
    if (file.tempFile || file.baseRaw) return Promise.resolve(file.baseRaw);

    // if files are renamed, their base path has changed
    const filePath =
      file.mrChange && file.mrChange.renamed_file ? file.mrChange.old_path : file.path;

    return axios
      .get(
        joinPaths(
          gon.relative_url_root || '/',
          projectId,
          '-',
          'raw',
          ref,
          escapeFileUrl(filePath),
        ),
        {
          transformResponse: [(f) => f],
        },
      )
      .then(({ data }) => data);
  },
  getProjectData(namespace, project) {
    const projectPath = `${namespace}/${project}`;

    return Promise.all([fetchApiProjectData(projectPath), fetchGqlProjectData(projectPath)]).then(
      ([apiProjectData, gqlProjectData]) => ({
        data: {
          ...apiProjectData,
          ...gqlProjectData,
        },
      }),
    );
  },
  getProjectMergeRequests(projectId, params = {}) {
    return Api.projectMergeRequests(projectId, params);
  },
  getProjectMergeRequestData(projectId, mergeRequestId, params = {}) {
    return Api.projectMergeRequest(projectId, mergeRequestId, params);
  },
  getProjectMergeRequestChanges(projectId, mergeRequestId) {
    return Api.projectMergeRequestChanges(projectId, mergeRequestId);
  },
  getProjectMergeRequestVersions(projectId, mergeRequestId) {
    return Api.projectMergeRequestVersions(projectId, mergeRequestId);
  },
  getBranchData(projectId, currentBranchId) {
    return Api.branchSingle(projectId, currentBranchId);
  },
  commit(projectId, payload) {
    return Api.commitMultiple(projectId, payload);
  },
  getFiles(projectPath, ref) {
    const url = `${gon.relative_url_root}/${projectPath}/-/files/${ref}`;
    return axios.get(url, { params: { format: 'json' } });
  },
  lastCommitPipelines({ getters }) {
    const commitSha = getters.lastCommit.id;
    return Api.commitPipelines(getters.currentProject.path_with_namespace, commitSha);
  },
  pingUsage(projectPath) {
    const url = `${gon.relative_url_root}/${projectPath}/service_ping/web_ide_pipelines_count`;
    return axios.post(url);
  },
  getCiConfig(projectPath, content) {
    return query({
      query: ciConfig,
      variables: { projectPath, content },
    }).then(({ data }) => data.ciConfig);
  },
  dismissUserCallout(name) {
    return mutate({
      mutation: dismissUserCallout,
      variables: { input: { featureName: name } },
    }).then(({ data }) => data);
  },
};
