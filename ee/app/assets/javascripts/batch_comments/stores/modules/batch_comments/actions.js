import flash from '~/flash';
import { __ } from '~/locale';
import service from '../../../services/drafts_service';
import * as types from './mutation_types';

export const enableBatchComments = ({ commit }) => {
  commit(types.ENABLE_BATCH_COMMENTS);
};

export const saveDraft = ({ dispatch }, draft) =>
  dispatch('saveNote', { ...draft, isDraft: true }, { root: true });

export const addDraftToDiscussion = ({ commit }, { endpoint, data }) =>
  service
    .addDraftToDiscussion(endpoint, data)
    .then(res => res.json())
    .then(res => {
      commit(types.ADD_NEW_DRAFT, res);
      return res;
    })
    .catch(() => {
      flash(__('An error occurred adding a draft to the discussion.'));
    });

export const createNewDraft = ({ commit }, { endpoint, data }) =>
  service
    .createNewDraft(endpoint, data)
    .then(res => res.json())
    .then(res => {
      commit(types.ADD_NEW_DRAFT, res);
      return res;
    })
    .catch(() => {
      flash(__('An error occurred adding a new draft.'));
    });

export const deleteDraft = ({ commit, getters }, draft) =>
  service
    .deleteDraft(getters.getNotesData.draftsPath, draft.id)
    .then(() => {
      commit(types.DELETE_DRAFT, draft.id);
    })
    .catch(() => flash(__('An error occurred while deleting the comment')));

export const fetchDrafts = ({ commit, getters }) =>
  service
    .fetchDrafts(getters.getNotesData.draftsPath)
    .then(res => res.json())
    .then(data => commit(types.SET_BATCH_COMMENTS_DRAFTS, data))
    .catch(() => flash(__('An error occurred while fetching pending comments')));

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

export const updateDiscussionsAfterPublish = ({ dispatch, getters, rootGetters }) =>
  dispatch('fetchDiscussions', getters.getNotesData.discussionsPath, { root: true }).then(() =>
    dispatch('diffs/assignDiscussionsToDiff', rootGetters.discussionsStructuredByLineCode, {
      root: true,
    }),
  );

export const discardReview = ({ commit, getters }) => {
  commit(types.REQUEST_DISCARD_REVIEW);

  return service
    .discard(getters.getNotesData.draftsDiscardPath)
    .then(() => commit(types.RECEIVE_DISCARD_REVIEW_SUCCESS))
    .catch(() => commit(types.RECEIVE_DISCARD_REVIEW_ERROR));
};

export const updateDraft = ({ commit, getters }, { note, noteText, callback }) =>
  service
    .update(getters.getNotesData.draftsPath, { draftId: note.id, note: noteText })
    .then(res => res.json())
    .then(data => commit(types.RECEIVE_DRAFT_UPDATE_SUCCESS, data))
    .then(callback)
    .catch(() => flash(__('An error occurred while updating the comment')));

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
