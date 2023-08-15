import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import notesModule from './modules';

Vue.use(Vuex);

// NOTE: Giving the option to either use a singleton or new instance of notes.
const notesStore = () => new Vuex.Store(notesModule());

export default notesStore;
export const store = notesStore();
