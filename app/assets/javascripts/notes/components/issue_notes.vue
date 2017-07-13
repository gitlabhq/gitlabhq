<script>
/* global Flash */

import Vue from 'vue';
import Vuex from 'vuex';
import storeOptions from '../stores/issue_notes_store';
import eventHub from '../event_hub';
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
  computed: {
    ...Vuex.mapGetters([
      'notes',
      'notesById',
    ]),
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
    fetchNotes() {
      const { discussionsPath } = this.$el.parentNode.dataset;

      this.$store.dispatch('fetchNotes', discussionsPath)
        .then(() => {
          this.isLoading = false;

          // Scroll to note if we have hash fragment in the page URL
          Vue.nextTick(() => {
            this.checkLocationHash();
          });
        })
        .catch(() => {
          new Flash('Something went wrong while fetching issue comments. Please try again.'); // eslint-disable-line
        });
    },
    initPolling() {
      const { lastFetchedAt } = $('.js-notes-wrapper')[0].dataset;
      this.$store.commit('setLastFetchedAt', lastFetchedAt);

      // FIXME: @fatihacet Implement real polling mechanism
      setInterval(() => {
        this.$store.dispatch('poll')
          .then((res) => {
            this.$store.commit('setLastFetchedAt', res.lastFetchedAt);
          })
          .catch(() => {
            new Flash('Something went wrong while fetching latest comments.'); // eslint-disable-line
          });
      }, 15000);
    },
    bindEventHubListeners() {
      eventHub.$on('toggleAward', (data) => {
        const { awardName, noteId } = data;
        const endpoint = this.notesById[noteId].toggle_award_path;

        this.$store.dispatch('toggleAward', { endpoint, awardName, noteId })
          .catch(() => {
            new Flash('Something went wrong on our end.'); // eslint-disable-line
          });
      });

      $(document).on('issuable:change', (e, isClosed) => {
        eventHub.$emit('IssueStateChanged', isClosed);
      });
    },
    checkLocationHash() {
      const hash = gl.utils.getLocationHash();
      const $el = $(`#${hash}`);

      if (hash && $el) {
        this.$store.commit('setTargetNoteHash', hash);
        this.$store.dispatch('scrollToNoteIfNeeded', $el);
      }
    },
  },
  mounted() {
    this.fetchNotes();
    this.initPolling();
    this.bindEventHubListeners();
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
        v-for="note in notes"
        :is="component(note)"
        :note="componentData(note)"
        :key="note.id" />
    </ul>
    <issue-comment-form v-if="!isLoading" />
  </div>
</template>
