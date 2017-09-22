<script>
  /* global Flash */
  import { mapGetters, mapActions } from 'vuex';
  import store from '../stores/';
  import * as constants from '../constants';
  import issueNote from './issue_note.vue';
  import issueDiscussion from './issue_discussion.vue';
  import issueSystemNote from './issue_system_note.vue';
  import issueCommentForm from './issue_comment_form.vue';
  import placeholderNote from './issue_placeholder_note.vue';
  import placeholderSystemNote from './issue_placeholder_system_note.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';

  export default {
    name: 'issueNotesApp',
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
        required: false,
        default: {},
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
        const options = {
          path: this.getNotesDataByProp('discussionsPath'),
          params: { limit: 3 },
        }

        // FIXME: This should be changed.
        this.isLoading = false;

        return this.actionFetchNotes(options)
          .then(() => {
            this.initPolling()
          })
          .then(() => {
            this.isLoading = false;
          })
          .then(() => this.$nextTick())
          .then(() => this.checkLocationHash())
          .catch(() => {
            this.isLoading = false;
            Flash('Something went wrong while fetching issue comments. Please try again.');
          });
      },
      initPolling() {
        this.setLastFetchedAt(this.getNotesDataByProp('lastFetchedAt'));

        this.poll();
      },
    },
    created() {
      this.setNotesData(this.notesData);
      this.setIssueData(this.issueData);
      this.setUserData(this.userData);
    },
    mounted() {
      this.fetchNotes();

      const parentElement = this.$el.parentElement;

      if (parentElement &&
        parentElement.classList.contains('js-vue-notes-event')) {
        parentElement.addEventListener('toggleAward', (event) => {
          const { awardName, noteId } = event.detail;
          this.actionToggleAward({ awardName, noteId });
        });
      }
    },
  };
</script>

<template>
  <div id="notes">
    <div
      v-if="isLoading"
      class="js-loading loading">
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
