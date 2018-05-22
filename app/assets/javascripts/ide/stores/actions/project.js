import Visibility from 'visibilityjs';
import flash from '~/flash';
import { __ } from '~/locale';
import service from '../../services';
import * as types from '../mutation_types';
import Poll from '../../../lib/utils/poll';

let eTagPoll;

export const getProjectData = (
  { commit, state, dispatch },
  { namespace, projectId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[`${namespace}/${projectId}`] || force) {
      commit(types.TOGGLE_LOADING, { entry: state });
      service
        .getProjectData(namespace, projectId)
        .then(res => res.data)
        .then(data => {
          commit(types.TOGGLE_LOADING, { entry: state });
          commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
          if (!state.currentProjectId)
            commit(types.SET_CURRENT_PROJECT, `${namespace}/${projectId}`);
          resolve(data);
        })
        .catch(() => {
          flash(
            __('Error loading project data. Please try again.'),
            'alert',
            document,
            null,
            false,
            true,
          );
          reject(new Error(`Project not loaded ${namespace}/${projectId}`));
        });
    } else {
      resolve(state.projects[`${namespace}/${projectId}`]);
    }
  });

export const getBranchData = (
  { commit, state, dispatch },
  { projectId, branchId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (
      typeof state.projects[`${projectId}`] === 'undefined' ||
      !state.projects[`${projectId}`].branches[branchId] ||
      force
    ) {
      service
        .getBranchData(`${projectId}`, branchId)
        .then(({ data }) => {
          const { id } = data.commit;
          commit(types.SET_BRANCH, {
            projectPath: `${projectId}`,
            branchName: branchId,
            branch: data,
          });
          commit(types.SET_BRANCH_WORKING_REFERENCE, { projectId, branchId, reference: id });
          resolve(data);
        })
        .catch(() => {
          flash(
            __('Error loading branch data. Please try again.'),
            'alert',
            document,
            null,
            false,
            true,
          );
          reject(new Error(`Branch not loaded - ${projectId}/${branchId}`));
        });
    } else {
      resolve(state.projects[`${projectId}`].branches[branchId]);
    }
  });

export const refreshLastCommitData = ({ commit, state, dispatch }, { projectId, branchId } = {}) =>
  service
    .getBranchData(projectId, branchId)
    .then(({ data }) => {
      commit(types.SET_BRANCH_COMMIT, {
        projectId,
        branchId,
        commit: data.commit,
      });
    })
    .catch(() => {
      flash(__('Error loading last commit.'), 'alert', document, null, false, true);
    });

export const pollSuccessCallBack = ({ commit, state, dispatch }, { data }) => {
  if (data.pipelines && data.pipelines.length) {
    const lastCommitHash =
      state.projects[state.currentProjectId].branches[state.currentBranchId].commit.id;
    const lastCommitPipeline = data.pipelines.find(
      pipeline => pipeline.commit.id === lastCommitHash,
    );
    commit(types.SET_LAST_COMMIT_PIPELINE, {
      projectId: state.currentProjectId,
      branchId: state.currentBranchId,
      pipeline: lastCommitPipeline || {},
    });
  }

  return data;
};

export const pipelinePoll = ({ getters, dispatch }) => {
  eTagPoll = new Poll({
    resource: service,
    method: 'lastCommitPipelines',
    data: {
      getters,
    },
    successCallback: ({ data }) => dispatch('pollSuccessCallBack', { data }),
    errorCallback: () => {
      flash(
        __('Something went wrong while fetching the latest pipeline status.'),
        'alert',
        document,
        null,
        false,
        true,
      );
    },
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      eTagPoll.restart();
    } else {
      eTagPoll.stop();
    }
  });
};

export const stopPipelinePolling = () => {
  eTagPoll.stop();
};

export const restartPipelinePolling = () => {
  eTagPoll.restart();
};
