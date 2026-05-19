import { parseBoolean, getCookie } from '~/lib/utils/common_utils';
import { getLocationHash, getParameterValues } from '~/lib/utils/url_utility';
import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { DIFF_VIEW_COOKIE_NAME, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import initCherryPickCommitModal from '~/projects/commit/init_cherry_pick_commit_modal';
import initRevertCommitModal from '~/projects/commit/init_revert_commit_modal';
import { useNotes } from '~/notes/store/legacy_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useCodeReview } from '~/diffs/stores/code_review';
import { pinia } from '~/pinia/instance';
import MergeRequest from '../merge_request';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';
import { initMrStateLazyLoad } from './init_state_lazy_load';

export function setupNotesState(notesDataset) {
  const noteableData = JSON.parse(notesDataset.noteableData);
  noteableData.noteableType = notesDataset.noteableType;
  noteableData.targetType = notesDataset.targetType;
  noteableData.discussion_locked = parseBoolean(notesDataset.isLocked);
  noteableData.archived = parseBoolean(notesDataset.archived);
  const notesData = JSON.parse(notesDataset.notesData);
  const currentUserData = JSON.parse(notesDataset.currentUserData);
  const endpoints = { metadata: notesDataset.endpointMetadata };

  useNotes().setNotesData(notesData);
  useNotes().setNoteableData(noteableData);
  useNotes().setUserData(currentUserData);
  useNotes().setTargetNoteHash(getLocationHash());
  useMrNotes(pinia).setEndpoints(endpoints);
}

export function setupDiffsState(diffsDataset) {
  const { mrPath } = getDerivedMergeRequestInformation({ endpoint: diffsDataset.endpoint });

  useLegacyDiffs(pinia).setBaseConfig({
    endpoint: diffsDataset.endpoint,
    endpointMetadata: diffsDataset.endpointMetadata,
    endpointBatch: diffsDataset.endpointBatch,
    endpointDiffForPath: diffsDataset.endpointDiffForPath,
    endpointCoverage: diffsDataset.endpointCoverage,
    endpointUpdateUser: diffsDataset.updateCurrentUserPath,
    projectPath: diffsDataset.projectPath,
    dismissEndpoint: diffsDataset.dismissEndpoint,
    showSuggestPopover: parseBoolean(diffsDataset.showSuggestPopover),
    viewDiffsFileByFile: parseBoolean(diffsDataset.fileByFileDefault),
    defaultSuggestionCommitMessage: diffsDataset.defaultSuggestionCommitMessage,
    diffViewType:
      getParameterValues('view')[0] || getCookie(DIFF_VIEW_COOKIE_NAME) || INLINE_DIFF_VIEW_TYPE,
    perPage: Number(diffsDataset.perPage),
  });
  if (!mrPath) return;
  useCodeReview().setMrPath(mrPath);
  useCodeReview().restoreFromAutosave();
  useCodeReview().restoreFromLegacyMrReviews();
}

export default function initMrNotes(createRapidDiffsApp) {
  resetServiceWorkersPublicPath();

  const discussionsEl = document.getElementById('js-vue-mr-discussions');
  const diffsEl = document.getElementById('js-diffs-app');
  setupNotesState(discussionsEl.dataset);
  if (diffsEl) {
    setupDiffsState(diffsEl.dataset);
  } else {
    const rapidDiffsEl = document.querySelector('[data-rapid-diffs]');
    if (rapidDiffsEl) {
      const appData = JSON.parse(rapidDiffsEl.dataset.appData);
      useLegacyDiffs(pinia).$patch({
        projectPath: appData.project_path,
        defaultSuggestionCommitMessage: appData.default_suggestion_commit_message,
      });
    }
  }

  const mrShowNode = document.querySelector('.merge-request');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrShowNode.dataset.mrAction,
    createRapidDiffsApp,
  });

  initMrStateLazyLoad(createRapidDiffsApp);

  document.addEventListener('merged:UpdateActions', () => {
    initRevertCommitModal('i_code_review_post_merge_submit_revert_modal');
    initCherryPickCommitModal('i_code_review_post_merge_submit_cherry_pick_modal');
  });
}
