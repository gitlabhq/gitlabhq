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
  createNewNote(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
  poll(data = {}) {
    const { endpoint, lastFetchedAt } = data;
    const options = {
      headers: {
        'X-Last-Fetched-At': lastFetchedAt,
      },
    };

    return Vue.http.get(endpoint, options);
  },
  toggleAward(endpoint, data) {
    return Vue.http.post(endpoint, data, { emulateJSON: true });
  },
};
