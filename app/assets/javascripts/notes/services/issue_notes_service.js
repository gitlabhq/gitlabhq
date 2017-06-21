import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default {
  fetchNotes(endpoint) {
    return Vue.http.get(endpoint);
  },
  deleteNote(endpoint) {
    return Vue.http.delete(endpoint);
  },
  replyToDiscussion(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
  updateNote(endpoint, data) {
    return Vue.http.put(endpoint, data, { emulateJSON: true });
  },
};
