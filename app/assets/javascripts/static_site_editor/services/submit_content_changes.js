import Api from '~/api';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import generateBranchName from '~/static_site_editor/services/generate_branch_name';
import Tracking from '~/tracking';

import {
  SUBMIT_CHANGES_BRANCH_ERROR,
  SUBMIT_CHANGES_COMMIT_ERROR,
  SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
  TRACKING_ACTION_CREATE_COMMIT,
  TRACKING_ACTION_CREATE_MERGE_REQUEST,
  SERVICE_PING_TRACKING_ACTION_CREATE_COMMIT,
  SERVICE_PING_TRACKING_ACTION_CREATE_MERGE_REQUEST,
  DEFAULT_FORMATTING_CHANGES_COMMIT_MESSAGE,
  DEFAULT_FORMATTING_CHANGES_COMMIT_DESCRIPTION,
} from '../constants';

const createBranch = (projectId, branch, targetBranch) =>
  Api.createBranch(projectId, {
    ref: targetBranch,
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
    const imageExistsInMarkdown = (path) => new RegExp(`!\\[([^[\\]\\n]*)\\](\\(${path})\\)`); // matches the image markdown syntax: ![<any-string-except-newline>](<path>)

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

const createUpdateSourceFileAction = (sourcePath, content) => [
  convertObjectPropsToSnakeCase({
    action: 'update',
    filePath: sourcePath,
    content,
  }),
];

const commit = (projectId, message, branch, actions) => {
  Tracking.event(document.body.dataset.page, TRACKING_ACTION_CREATE_COMMIT);
  Api.trackRedisCounterEvent(SERVICE_PING_TRACKING_ACTION_CREATE_COMMIT);

  return Api.commitMultiple(
    projectId,
    convertObjectPropsToSnakeCase({
      branch,
      commitMessage: message,
      actions,
    }),
  ).catch(() => {
    throw new Error(SUBMIT_CHANGES_COMMIT_ERROR);
  });
};

const createMergeRequest = (projectId, title, description, sourceBranch, targetBranch) => {
  Tracking.event(document.body.dataset.page, TRACKING_ACTION_CREATE_MERGE_REQUEST);
  Api.trackRedisCounterEvent(SERVICE_PING_TRACKING_ACTION_CREATE_MERGE_REQUEST);

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
  targetBranch,
  content,
  images,
  mergeRequestMeta,
  formattedMarkdown,
}) => {
  const branch = generateBranchName(username, targetBranch);
  const { title: mergeRequestTitle, description: mergeRequestDescription } = mergeRequestMeta;
  const meta = {};

  return createBranch(projectId, branch, targetBranch)
    .then(({ data: { web_url: url } }) => {
      const message = `${DEFAULT_FORMATTING_CHANGES_COMMIT_MESSAGE}\n\n${DEFAULT_FORMATTING_CHANGES_COMMIT_DESCRIPTION}`;

      Object.assign(meta, { branch: { label: branch, url } });

      return formattedMarkdown
        ? commit(
            projectId,
            message,
            branch,
            createUpdateSourceFileAction(sourcePath, formattedMarkdown),
          )
        : meta;
    })
    .then(() =>
      commit(projectId, mergeRequestTitle, branch, [
        ...createUpdateSourceFileAction(sourcePath, content),
        ...createImageActions(images, content),
      ]),
    )
    .then(({ data: { short_id: label, web_url: url } }) => {
      Object.assign(meta, { commit: { label, url } });

      return createMergeRequest(
        projectId,
        mergeRequestTitle,
        mergeRequestDescription,
        branch,
        targetBranch,
      );
    })
    .then(({ data: { iid: label, web_url: url } }) => {
      Object.assign(meta, { mergeRequest: { label: label.toString(), url } });

      return meta;
    });
};

export default submitContentChanges;
