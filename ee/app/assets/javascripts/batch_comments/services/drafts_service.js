import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default {
  createNewDraft(endpoint, data) {
    const postData = Object.assign({}, data, { draft_note: data.note });
    delete postData.note;

    return Vue.http.post(endpoint, postData, { emulateJSON: true });
  },
  deleteDraft(endpoint, draftId) {
    return Vue.http.delete(`${endpoint}/${draftId}`, { emulateJSON: true });
  },
  publishDraft(endpoint, draftId) {
    return Vue.http.post(endpoint, { id: draftId }, { emulateJSON: true });
  },
  addDraftToDiscussion(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
  fetchDrafts(endpoint) {
    return Vue.http.get(endpoint);
  },
  publish(endpoint) {
    return Vue.http.post(endpoint);
  },
  discard(endpoint) {
    return Vue.http.delete(endpoint);
  },
  update(endpoint, { draftId, note }) {
    return Vue.http.put(`${endpoint}/${draftId}`, { draft_note: { note } }, { emulateJSON: true });
  },
};
