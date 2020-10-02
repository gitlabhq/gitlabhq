import Api from '~/api';
import Tracking from '~/tracking';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import generateBranchName from '~/static_site_editor/services/generate_branch_name';

import {
  DEFAULT_TARGET_BRANCH,
  SUBMIT_CHANGES_BRANCH_ERROR,
  SUBMIT_CHANGES_COMMIT_ERROR,
  SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
  TRACKING_ACTION_CREATE_COMMIT,
  TRACKING_ACTION_CREATE_MERGE_REQUEST,
} from '../constants';

const createBranch = (projectId, branch) =>
  Api.createBranch(projectId, {
    ref: DEFAULT_TARGET_BRANCH,
    branch,
  }).catch(() => {
    throw new Error(SUBMIT_CHANGES_BRANCH_ERROR);
  });

const createImageActions = (images, markdown) => {
  const actions = [];

  if (!markdown) {
    return actions;
  }

  images.forEach((imageContent, filePath) => {
    const imageExistsInMarkdown = path => new RegExp(`!\\[([^[\\]\\n]*)\\](\\(${path})\\)`); // matches the image markdown syntax: ![<any-string-except-newline>](<path>)

    if (imageExistsInMarkdown(filePath).test(markdown)) {
      actions.push(
        convertObjectPropsToSnakeCase({
          encoding: 'base64',
          action: 'create',
          content: imageContent,
          filePath,
        }),
      );
    }
  });

  return actions;
};

const commitContent = (projectId, message, branch, sourcePath, content, images) => {
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
        ...createImageActions(images, content),
      ],
    }),
  ).catch(() => {
    throw new Error(SUBMIT_CHANGES_COMMIT_ERROR);
  });
};

const createMergeRequest = (
  projectId,
  title,
  description,
  sourceBranch,
  targetBranch = DEFAULT_TARGET_BRANCH,
) => {
  Tracking.event(document.body.dataset.page, TRACKING_ACTION_CREATE_MERGE_REQUEST);

  return Api.createProjectMergeRequest(
    projectId,
    convertObjectPropsToSnakeCase({
      title,
      description,
      sourceBranch,
      targetBranch,
    }),
  ).catch(() => {
    throw new Error(SUBMIT_CHANGES_MERGE_REQUEST_ERROR);
  });
};

const submitContentChanges = ({
  username,
  projectId,
  sourcePath,
  content,
  images,
  mergeRequestMeta,
}) => {
  const branch = generateBranchName(username);
  const { title: mergeRequestTitle, description: mergeRequestDescription } = mergeRequestMeta;
  const meta = {};

  return createBranch(projectId, branch)
    .then(({ data: { web_url: url } }) => {
      Object.assign(meta, { branch: { label: branch, url } });

      return commitContent(projectId, mergeRequestTitle, branch, sourcePath, content, images);
    })
    .then(({ data: { short_id: label, web_url: url } }) => {
      Object.assign(meta, { commit: { label, url } });

      return createMergeRequest(projectId, mergeRequestTitle, mergeRequestDescription, branch);
    })
    .then(({ data: { iid: label, web_url: url } }) => {
      Object.assign(meta, { mergeRequest: { label: label.toString(), url } });

      return meta;
    });
};

export default submitContentChanges;
