<script>
  /* global Flash */

  import Vue from 'vue';
  import { mapGetters, mapActions, mapMutations } from 'vuex';
  import store from '../stores/';
  import * as constants from '../constants'
  import eventHub from '../event_hub';
  import issueNote from './issue_note.vue';
  import issueDiscussion from './issue_discussion.vue';
  import issueSystemNote from './issue_system_note.vue';
  import issueCommentForm from './issue_comment_form.vue';
  import placeholderNote from './issue_placeholder_note.vue';
  import placeholderSystemNote from './issue_placeholder_system_note.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';

  export default {
    name: 'IssueNotes',
    props: {
      issueData: {
        type: Object,
        required: true,
      },
      notesData: {
        type: Object,
        required: true,
      },
      userData: {
        type: Object,
        required: true,
      },
    },
    store,
    data() {
      return {
        isLoading: true,
      };
    },
    components: {
      issueNote,
      issueDiscussion,
      issueSystemNote,
      issueCommentForm,
      loadingIcon,
      placeholderNote,
      placeholderSystemNote,
    },
    computed: {
      ...mapGetters([
        'notes',
        'notesById',
        'getNotesDataByProp',
      ]),
    },
    methods: {
      ...mapActions({
        actionFetchNotes: 'fetchNotes',
        poll: 'poll',
        actionToggleAward: 'toggleAward',
        scrollToNoteIfNeeded: 'scrollToNoteIfNeeded',
        setNotesData: 'setNotesData',
        setIssueData: 'setIssueData',
        setUserData: 'setUserData',
        setLastFetchedAt: 'setLastFetchedAt',
        setTargetNoteHash: 'setTargetNoteHash',
      }),
      getComponentName(note) {
        if (note.isPlaceholderNote) {
          if (note.placeholderType === constants.SYSTEM_NOTE) {
            return placeholderSystemNote;
          }
          return placeholderNote;
        } else if (note.individual_note) {
          return note.notes[0].system ? issueSystemNote : issueNote;
        }

        return issueDiscussion;
      },
      getComponentData(note) {
        return note.individual_note ? note.notes[0] : note;
      },
      fetchNotes() {
        this.actionFetchNotes(this.getNotesDataByProp('discussionsPath'))
          .then(() => {
            this.isLoading = false;

            // Scroll to note if we have hash fragment in the page URL
            this.$nextTick(() => {
              this.checkLocationHash();
            });
          })
          .catch((error) => Flash('Something went wrong while fetching issue comments. Please try again.'));
      },
      initPolling() {
        this.setLastFetchedAt(this.getNotesDataByProp('lastFetchedAt'));

        this.poll();
      },
      bindEventHubListeners() {
        this.$el.parentElement.addEventListener('toggleAward', (event) => {
          const { awardName, noteId } = event.detail;
          const endpoint = this.notesById[noteId].toggle_award_path;

          this.actionToggleAward({ endpoint, awardName, noteId })
            .catch((error) => Flash('Something went wrong on our end.'));
        });

        // JQuery is needed here because it is a custom event being dispatched with jQuery.
        $(document).on('issuable:change', (e, isClosed) => {
          eventHub.$emit('issueStateChanged', isClosed);
        });
      },
      checkLocationHash() {
        const hash = gl.utils.getLocationHash();
        const $el = $(`#${hash}`);

        if (hash && $el) {
          this.setTargetNoteHash(hash);
          this.scrollToNoteIfNeeded($el);
        }
      },
    },
    created() {
      this.setNotesData(this.notesData);
      this.setIssueData(this.issueData);
      this.setUserData(this.userData)
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
      <loading-icon />
    </div>

    <ul
      v-if="!isLoading"
      id="notes-list"
      class="notes main-notes-list timeline">

      <component
        v-for="note in notes"
        :is="getComponentName(note)"
        :note="getComponentData(note)"
        :key="note.id"
        />
    </ul>

    <issue-comment-form />
  </div>
</template>
