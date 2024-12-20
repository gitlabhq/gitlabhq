import { isEmpty } from 'lodash';
import { createAlert } from '~/alert';
import { scrollToElement } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { FILE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { updateNoteErrorMessage } from '~/notes/utils';
import { CHANGES_TAB, DISCUSSION_TAB, SHOW_TAB } from '../../../constants';
import service from '../../../services/drafts_service';
import * as types from './mutation_types';

export const saveDraft = ({ dispatch }, draft) =>
  dispatch('saveNote', { ...draft, isDraft: true }, { root: true });

export const addDraftToDiscussion = ({ commit }, { endpoint, data }) =>
  service
    .addDraftToDiscussion(endpoint, data)
    .then((res) => res.data)
    .then((res) => {
      commit(types.ADD_NEW_DRAFT, res);
      return res;
    })
    .catch((e) => {
      throw e.response;
    });

export const createNewDraft = ({ commit, dispatch }, { endpoint, data }) =>
  service
    .createNewDraft(endpoint, data)
    .then((res) => res.data)
    .then((res) => {
      commit(types.ADD_NEW_DRAFT, res);

      if (res.position?.position_type === FILE_DIFF_POSITION_TYPE) {
        dispatch('diffs/addDraftToFile', { filePath: res.file_path, draft: res }, { root: true });
      }

      return res;
    })
    .catch((e) => {
      throw e.response;
    });

export const deleteDraft = ({ commit, getters }, draft) =>
  service
    .deleteDraft(getters.getNotesData.draftsPath, draft.id)
    .then(() => {
      commit(types.DELETE_DRAFT, draft.id);
    })
    .catch(() =>
      createAlert({
        message: __('An error occurred while deleting the comment'),
      }),
    );

export const fetchDrafts = ({ commit, getters, state, dispatch }) =>
  service
    .fetchDrafts(getters.getNotesData.draftsPath)
    .then((res) => res.data)
    .then((data) => commit(types.SET_BATCH_COMMENTS_DRAFTS, data))
    .then(() => {
      state.drafts.forEach((draft) => {
        if (draft.position?.position_type === FILE_DIFF_POSITION_TYPE) {
          dispatch('diffs/addDraftToFile', { filePath: draft.file_path, draft }, { root: true });
        } else if (!draft.line_code) {
          dispatch('convertToDiscussion', draft.discussion_id, { root: true });
        }
      });
    })
    .catch(() =>
      createAlert({
        message: __('An error occurred while fetching pending comments'),
      }),
    );

export const publishSingleDraft = ({ commit, getters }, draftId) => {
  commit(types.REQUEST_PUBLISH_DRAFT, draftId);

  service
    .publishDraft(getters.getNotesData.draftsPublishPath, draftId)
    .then(() => commit(types.RECEIVE_PUBLISH_DRAFT_SUCCESS, draftId))
    .catch(() => commit(types.RECEIVE_PUBLISH_DRAFT_ERROR, draftId));
};

export const publishReview = ({ commit, getters }, noteData = {}) => {
  commit(types.REQUEST_PUBLISH_REVIEW);

  return service
    .publish(getters.getNotesData.draftsPublishPath, noteData)
    .then(() => commit(types.RECEIVE_PUBLISH_REVIEW_SUCCESS))
    .catch((e) => {
      commit(types.RECEIVE_PUBLISH_REVIEW_ERROR);

      throw e.response;
    });
};

export const updateDraft = (
  { commit, getters },
  { note, noteText, resolveDiscussion, position, flashContainer, callback, errorCallback },
) => {
  const params = {
    draftId: note.id,
    note: noteText,
    resolveDiscussion,
  };
  // Stringifying an empty object yields `{}` which breaks graphql queries
  // https://gitlab.com/gitlab-org/gitlab/-/issues/298827
  if (!isEmpty(position)) params.position = JSON.stringify(position);

  return service
    .update(getters.getNotesData.draftsPath, params)
    .then((res) => res.data)
    .then((data) => commit(types.RECEIVE_DRAFT_UPDATE_SUCCESS, data))
    .then(callback)
    .catch((e) => {
      createAlert({
        message: updateNoteErrorMessage(e),
        parent: flashContainer,
      });

      errorCallback();
    });
};

export const scrollToDraft = ({ dispatch, rootGetters }, draft) => {
  const discussion = draft.discussion_id && rootGetters.getDiscussion(draft.discussion_id);
  const tab =
    draft.file_hash || (discussion && discussion.diff_discussion) ? CHANGES_TAB : SHOW_TAB;
  const tabEl = tab === CHANGES_TAB ? CHANGES_TAB : DISCUSSION_TAB;
  const draftID = `note_${draft.id}`;
  const el = document.querySelector(`#${tabEl} #${draftID}`);

  window.location.hash = draftID;

  if (window.mrTabs.currentAction !== tab) {
    window.mrTabs.tabShown(tab);
  }

  const { file_path: filePath } = draft;

  if (filePath) {
    dispatch('diffs/setFileCollapsedAutomatically', { filePath, collapsed: false }, { root: true });
  }

  if (discussion) {
    dispatch('expandDiscussion', { discussionId: discussion.id }, { root: true });
  }

  if (el) {
    setTimeout(() => scrollToElement(el.closest('.draft-note-component')));
  }
};

export const expandAllDiscussions = ({ dispatch, state }) =>
  state.drafts
    .filter((draft) => draft.discussion_id)
    .forEach((draft) => {
      dispatch('expandDiscussion', { discussionId: draft.discussion_id }, { root: true });
    });

export const toggleResolveDiscussion = ({ commit }, draftId) => {
  commit(types.TOGGLE_RESOLVE_DISCUSSION, draftId);
};

export const clearDrafts = ({ commit }) => commit(types.CLEAR_DRAFTS);

export const discardDrafts = ({ getters, commit }) => {
  return service
    .discard(getters.getNotesData.draftsDiscardPath)
    .then(() => {
      commit(types.CLEAR_DRAFTS);
    })
    .catch((error) =>
      createAlert({
        captureError: true,
        error,
        message: __('An error occurred while discarding your review. Please try again.'),
      }),
    );
};
