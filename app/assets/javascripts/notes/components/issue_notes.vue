<script>
/* global Flash */

import Vue from 'vue';
import Vuex from 'vuex';
import storeOptions from '../stores/issue_notes_store';
import IssueNote from './issue_note.vue';
import IssueDiscussion from './issue_discussion.vue';
import IssueSystemNote from './issue_system_note.vue';
import IssueCommentForm from './issue_comment_form.vue';

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
    IssueSystemNote,
    IssueCommentForm,
  },
  methods: {
    component(note) {
      if (note.individual_note) {
        return note.notes[0].system ? IssueSystemNote : IssueNote;
      }

      return IssueDiscussion;
    },
    componentData(note) {
      return note.individual_note ? note.notes[0] : note;
    },
  },
  mounted() {
    const path = this.$el.parentNode.dataset.discussionsPath;
    this.$store.dispatch('fetchNotes', path)
      .then(() => {
        this.isLoading = false;
      })
      .catch(() => {
        new Flash('Something went wrong while fetching issue comments. Please try again.'); // eslint-disable-line
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
        class="fa fa-spinner fa-spin"
        aria-hidden="true"></i>
    </div>
    <ul
      v-if="!isLoading"
      id="notes-list"
      class="notes main-notes-list timeline">
      <component
        v-for="note in $store.getters.notes"
        :is="component(note)"
        :note="componentData(note)"
        :key="note.id" />
    </ul>
    <issue-comment-form v-if="!isLoading" />
  </div>
</template>
