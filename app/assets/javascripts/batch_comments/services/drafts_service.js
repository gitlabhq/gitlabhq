import axios from '~/lib/utils/axios_utils';

export default {
  createNewDraft(endpoint, data) {
    const postData = { ...data, draft_note: data.note };
    delete postData.note;

    return axios.post(endpoint, postData);
  },
  deleteDraft(endpoint, draftId) {
    return axios.delete(`${endpoint}/${draftId}`);
  },
  publishDraft(endpoint, draftId) {
    return axios.post(endpoint, { id: draftId });
  },
  addDraftToDiscussion(endpoint, data) {
    return axios.post(endpoint, data);
  },
  fetchDrafts(endpoint) {
    return axios.get(endpoint);
  },
  publish(endpoint, noteData) {
    return axios.post(endpoint, noteData);
  },
  discard(endpoint) {
    return axios.delete(endpoint);
  },
  update(endpoint, { draftId, note, resolveDiscussion, position }) {
    return axios.put(`${endpoint}/${draftId}`, {
      draft_note: { note, resolve_discussion: resolveDiscussion, position },
    });
  },
};
