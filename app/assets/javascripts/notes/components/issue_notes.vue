<script>
import Vue from 'vue';
import Vuex from 'vuex';
import storeOptions from '../stores/issue_notes_store';
import IssueNote from './issue_note.vue';
import IssueDiscussion from './issue_discussion.vue';

Vue.use(Vuex);
const store = new Vuex.Store(storeOptions);

export default {
  name: 'IssueNotes',
  store,
  data() {
    return {
      isLoading: true,
    };
  },
  components: {
    IssueNote,
    IssueDiscussion,
  },
  methods: {
    component(note) {
      return note.individual_note ? IssueNote : IssueDiscussion;
    },
    componentData(note) {
      return note.individual_note ? note.notes[0] : note;
    },
  },
  mounted() {
    const path = this.$el.parentNode.dataset.discussionsPath;
    this.$store.dispatch('fetchNotes', path)
      .finally(() => {
        this.isLoading = false;
      });
  },
};
</script>

<template>
  <div id="notes">
    <div
      v-if="isLoading"
      class="loading">
      <i
        aria-hidden="true"
        class="fa fa-spinner fa-spin"></i>
    </div>
    <ul
      class="notes main-notes-list timeline"
      id="notes-list">
      <component
        v-for="note in $store.getters.notes"
        :is="component(note)"
        :note="componentData(note)"
        :key="note.id" />
    </ul>
  </div>
</template>
