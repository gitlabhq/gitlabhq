import { isEmpty } from 'lodash';
import createFlash from '~/flash';
import { scrollToElement } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
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
    .catch(() => {
      createFlash({
        message: __('An error occurred adding a draft to the thread.'),
      });
    });

export const createNewDraft = ({ commit }, { endpoint, data }) =>
  service
    .createNewDraft(endpoint, data)
    .then((res) => res.data)
    .then((res) => {
      commit(types.ADD_NEW_DRAFT, res);
      return res;
    })
    .catch(() => {
      createFlash({
        message: __('An error occurred adding a new draft.'),
      });
    });

export const deleteDraft = ({ commit, getters }, draft) =>
  service
    .deleteDraft(getters.getNotesData.draftsPath, draft.id)
    .then(() => {
      commit(types.DELETE_DRAFT, draft.id);
    })
    .catch(() =>
      createFlash({
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
        if (!draft.line_code) {
          dispatch('convertToDiscussion', draft.discussion_id, { root: true });
        }
      });
    })
    .catch(() =>
      createFlash({
        message: __('An error occurred while fetching pending comments'),
      }),
    );

export const publishSingleDraft = ({ commit, dispatch, getters }, draftId) => {
  commit(types.REQUEST_PUBLISH_DRAFT, draftId);

  service
    .publishDraft(getters.getNotesData.draftsPublishPath, draftId)
    .then(() => dispatch('updateDiscussionsAfterPublish'))
    .then(() => commit(types.RECEIVE_PUBLISH_DRAFT_SUCCESS, draftId))
    .catch(() => commit(types.RECEIVE_PUBLISH_DRAFT_ERROR, draftId));
};

export const publishReview = ({ commit, dispatch, getters }) => {
  commit(types.REQUEST_PUBLISH_REVIEW);

  return service
    .publish(getters.getNotesData.draftsPublishPath)
    .then(() => dispatch('updateDiscussionsAfterPublish'))
    .then(() => commit(types.RECEIVE_PUBLISH_REVIEW_SUCCESS))
    .catch(() => commit(types.RECEIVE_PUBLISH_REVIEW_ERROR));
};

export const updateDiscussionsAfterPublish = async ({ dispatch, getters, rootGetters }) => {
  if (window.gon?.features?.paginatedNotes) {
    await dispatch('stopPolling', null, { root: true });
    await dispatch('fetchData', null, { root: true });
    await dispatch('restartPolling', null, { root: true });
  } else {
    await dispatch(
      'fetchDiscussions',
      { path: getters.getNotesData.discussionsPath },
      { root: true },
    );
  }

  dispatch('diffs/assignDiscussionsToDiff', rootGetters.discussionsStructuredByLineCode, {
    root: true,
  });
};

export const updateDraft = (
  { commit, getters },
  { note, noteText, resolveDiscussion, position, callback },
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
    .catch(() =>
      createFlash({
        message: __('An error occurred while updating the comment'),
      }),
    );
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
