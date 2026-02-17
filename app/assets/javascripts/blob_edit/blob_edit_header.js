import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import BlobEditHeader from '~/repository/pages/blob_edit_header.vue';

export default function initBlobEditHeader(editor) {
  const el = document.querySelector('.js-blob-edit-header');

  if (!el) {
    return null;
  }

  const {
    action,
    updatePath,
    cancelPath,
    originalBranch,
    targetBranch,
    canPushCode,
    canPushToBranch,
    emptyRepo,
    blobName,
    branchAllowsCollaboration,
    lastCommitSha,
    projectId,
    projectPath,
    newMergeRequestPath,
    targetProjectId,
    targetProjectPath,
    nextForkBranchName,
  } = el.dataset;

  return new Vue({
    el,
    name: 'BlobEditHeaderRoot',
    provide: {
      action,
      editor,
      updatePath,
      cancelPath,
      originalBranch,
      targetBranch,
      blobName,
      lastCommitSha,
      projectId,
      projectPath,
      newMergeRequestPath,
      targetProjectId,
      targetProjectPath,
      nextForkBranchName,
      emptyRepo: parseBoolean(emptyRepo),
      canPushCode: parseBoolean(canPushCode),
      canPushToBranch: parseBoolean(canPushToBranch),
      branchAllowsCollaboration: parseBoolean(branchAllowsCollaboration),
    },
    render: (createElement) => createElement(BlobEditHeader),
  });
}
