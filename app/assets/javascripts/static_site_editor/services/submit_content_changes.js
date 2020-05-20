import Api from '~/api';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import generateBranchName from '~/static_site_editor/services/generate_branch_name';

import {
  DEFAULT_TARGET_BRANCH,
  SUBMIT_CHANGES_BRANCH_ERROR,
  SUBMIT_CHANGES_COMMIT_ERROR,
  SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
  TRACKING_ACTION_CREATE_COMMIT,
} from '../constants';

const createBranch = (projectId, branch) =>
  Api.createBranch(projectId, {
    ref: DEFAULT_TARGET_BRANCH,
    branch,
  }).catch(() => {
    throw new Error(SUBMIT_CHANGES_BRANCH_ERROR);
  });

const commitContent = (projectId, message, branch, sourcePath, content) => {
  Tracking.event(document.body.dataset.page, TRACKING_ACTION_CREATE_COMMIT);

  return Api.commitMultiple(
    projectId,
    convertObjectPropsToSnakeCase({
      branch,
      commitMessage: message,
      actions: [
        convertObjectPropsToSnakeCase({
          action: 'update',
          filePath: sourcePath,
          content,
        }),
      ],
    }),
  ).catch(() => {
    throw new Error(SUBMIT_CHANGES_COMMIT_ERROR);
  });
};

const createMergeRequest = (projectId, title, sourceBranch, targetBranch = DEFAULT_TARGET_BRANCH) =>
  Api.createProjectMergeRequest(
    projectId,
    convertObjectPropsToSnakeCase({
      title,
      sourceBranch,
      targetBranch,
    }),
  ).catch(() => {
    throw new Error(SUBMIT_CHANGES_MERGE_REQUEST_ERROR);
  });

const submitContentChanges = ({ username, projectId, sourcePath, content }) => {
  const branch = generateBranchName(username);
  const mergeRequestTitle = sprintf(s__(`StaticSiteEditor|Update %{sourcePath} file`), {
    sourcePath,
  });
  const meta = {};

  return createBranch(projectId, branch)
    .then(({ data: { web_url: url } }) => {
      Object.assign(meta, { branch: { label: branch, url } });

      return commitContent(projectId, mergeRequestTitle, branch, sourcePath, content);
    })
    .then(({ data: { short_id: label, web_url: url } }) => {
      Object.assign(meta, { commit: { label, url } });

      return createMergeRequest(projectId, mergeRequestTitle, branch);
    })
    .then(({ data: { iid: label, web_url: url } }) => {
      Object.assign(meta, { mergeRequest: { label: label.toString(), url } });

      return meta;
    });
};

export default submitContentChanges;
