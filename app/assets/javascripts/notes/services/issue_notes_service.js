import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default {
  fetchNotes(endpoint) {
    return Vue.http.get(endpoint);
  },
  deleteNote(endpoint) {
    return Vue.http.get(endpoint);
  },
};
