<script>
  /* global Flash */

  import Vue from 'vue';
  import { mapGetters, mapActions, mapMutations } from 'vuex';
  import store from '../stores/';
  import * as constants from '../constants'
  import * as types from '../stores/mutation_types';
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
      ]),
    },
    methods: {
      ...mapActions({
        actionFetchNotes: 'fetchNotes',
      }),
      ...mapActions([
        'poll',
        'toggleAward',
        'scrollToNoteIfNeeded',
      ]),
      ...mapMutations({
        setLastFetchedAt: types.SET_LAST_FETCHED_AT,
        setTargetNoteHash: types.SET_TARGET_NOTE_HASH,
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
        const { discussionsPath } = this.$el.parentNode.dataset;

        this.actionFetchNotes(discussionsPath)
          .then(() => {
            this.isLoading = false;

            // Scroll to note if we have hash fragment in the page URL
            Vue.nextTick(() => {
              this.checkLocationHash();
            });
          })
          .catch(() => {
            Flash('Something went wrong while fetching issue comments. Please try again.');
          });
      },
      initPolling() {
        const { lastFetchedAt } = $('.js-notes-wrapper')[0].dataset;
        this.setLastFetchedAt(lastFetchedAt);

        // FIXME: @fatihacet Implement real polling mechanism
        setInterval(() => {
          this.poll()
            .then((res) => {
              this.setLastFetchedAt(res.lastFetchedAt);
            })
            .catch(() => {
              Flash('Something went wrong while fetching latest comments.');
            });
        }, 15000);
      },
      bindEventHubListeners() {
        eventHub.$on('toggleAward', (data) => {
          const { awardName, noteId } = data;
          const endpoint = this.notesById[noteId].toggle_award_path;

          this.toggleAward({ endpoint, awardName, noteId })
            .catch(() => {new Flash('Something went wrong on our end.')});
        });

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
    <issue-comment-form v-if="!isLoading" />
  </div>
</template>
