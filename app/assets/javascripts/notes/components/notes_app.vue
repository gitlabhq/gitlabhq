<script>
import $ from 'jquery';
import { mapGetters, mapActions } from 'vuex';
import { getLocationHash } from '../../lib/utils/url_utility';
import Flash from '../../flash';
import store from '../stores/';
import * as constants from '../constants';
import noteableNote from './noteable_note.vue';
import noteableDiscussion from './noteable_discussion.vue';
import systemNote from '../../vue_shared/components/notes/system_note.vue';
import commentForm from './comment_form.vue';
import placeholderNote from '../../vue_shared/components/notes/placeholder_note.vue';
import placeholderSystemNote from '../../vue_shared/components/notes/placeholder_system_note.vue';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import skeletonLoadingContainer from '../../vue_shared/components/notes/skeleton_note.vue';

export default {
  name: 'NotesApp',
  components: {
    noteableNote,
    noteableDiscussion,
    systemNote,
    commentForm,
    loadingIcon,
    placeholderNote,
    placeholderSystemNote,
  },
  props: {
    noteableData: {
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
      default: () => ({}),
    },
  },
  store,
  data() {
    return {
      isLoading: true,
    };
  },
  computed: {
    ...mapGetters(['notes', 'getNotesDataByProp', 'discussionCount']),
    noteableType() {
      // FIXME -- @fatihacet Get this from JSON data.
      const { ISSUE_NOTEABLE_TYPE, MERGE_REQUEST_NOTEABLE_TYPE, EPIC_NOTEABLE_TYPE } = constants;

      if (this.noteableData.noteableType === EPIC_NOTEABLE_TYPE) {
        return EPIC_NOTEABLE_TYPE;
      }

      return this.noteableData.merge_params
        ? MERGE_REQUEST_NOTEABLE_TYPE
        : ISSUE_NOTEABLE_TYPE;
    },
    allNotes() {
      if (this.isLoading) {
        const totalNotes = parseInt(this.notesData.totalNotes, 10) || 0;

        return new Array(totalNotes).fill({
          isSkeletonNote: true,
        });
      }
      return this.notes;
    },
  },
  created() {
    this.setNotesData(this.notesData);
    this.setNoteableData(this.noteableData);
    this.setUserData(this.userData);
  },
  mounted() {
    this.fetchNotes();

    const parentElement = this.$el.parentElement;

    if (
      parentElement &&
      parentElement.classList.contains('js-vue-notes-event')
    ) {
      parentElement.addEventListener('toggleAward', event => {
        const { awardName, noteId } = event.detail;
        this.actionToggleAward({ awardName, noteId });
      });
    }
    document.addEventListener('refreshVueNotes', this.fetchNotes);
  },
  beforeDestroy() {
    document.removeEventListener('refreshVueNotes', this.fetchNotes);
  },
  methods: {
    ...mapActions({
      actionFetchNotes: 'fetchNotes',
      poll: 'poll',
      actionToggleAward: 'toggleAward',
      scrollToNoteIfNeeded: 'scrollToNoteIfNeeded',
      setNotesData: 'setNotesData',
      setNoteableData: 'setNoteableData',
      setUserData: 'setUserData',
      setLastFetchedAt: 'setLastFetchedAt',
      setTargetNoteHash: 'setTargetNoteHash',
    }),
    getComponentName(note) {
      if (note.isSkeletonNote) {
        return skeletonLoadingContainer;
      }
      if (note.isPlaceholderNote) {
        if (note.placeholderType === constants.SYSTEM_NOTE) {
          return placeholderSystemNote;
        }
        return placeholderNote;
      } else if (note.individual_note) {
        return note.notes[0].system ? systemNote : noteableNote;
      }

      return noteableDiscussion;
    },
    getComponentData(note) {
      return note.individual_note ? note.notes[0] : note;
    },
    fetchNotes() {
      return this.actionFetchNotes(this.getNotesDataByProp('discussionsPath'))
        .then(() => this.initPolling())
        .then(() => {
          this.isLoading = false;
        })
        .then(() => this.$nextTick())
        .then(() => this.checkLocationHash())
        .catch(() => {
          this.isLoading = false;
          Flash(
            'Something went wrong while fetching comments. Please try again.',
          );
        });
    },
    initPolling() {
      if (this.isPollingInitialized) {
        return;
      }

      this.setLastFetchedAt(this.getNotesDataByProp('lastFetchedAt'));

      this.poll();
      this.isPollingInitialized = true;
    },
    checkLocationHash() {
      const hash = getLocationHash();
      const element = document.getElementById(hash);

      if (hash && element) {
        this.setTargetNoteHash(hash);
        this.scrollToNoteIfNeeded($(element));
      }
    },
  },
};
</script>

<template>
  <div id="notes">
    <ul
      id="notes-list"
      class="notes main-notes-list timeline">

      <component
        v-for="note in allNotes"
        :is="getComponentName(note)"
        :note="getComponentData(note)"
        :key="note.id"
      />
    </ul>

    <comment-form
      :noteable-type="noteableType"
    />
  </div>
</template>
