<script>
import { mapGetters, mapActions } from 'vuex';
import { getLocationHash } from '../../lib/utils/url_utility';
import Flash from '../../flash';
import * as constants from '../constants';
import eventHub from '../event_hub';
import noteableNote from './noteable_note.vue';
import noteableDiscussion from './noteable_discussion.vue';
import systemNote from '../../vue_shared/components/notes/system_note.vue';
import commentForm from './comment_form.vue';
import placeholderNote from '../../vue_shared/components/notes/placeholder_note.vue';
import placeholderSystemNote from '../../vue_shared/components/notes/placeholder_system_note.vue';
import skeletonLoadingContainer from '../../vue_shared/components/notes/skeleton_note.vue';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';

export default {
  name: 'NotesApp',
  components: {
    noteableNote,
    noteableDiscussion,
    systemNote,
    commentForm,
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
    shouldShow: {
      type: Boolean,
      required: false,
      default: true,
    },
    markdownVersion: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      isFetching: false,
      currentFilter: null,
    };
  },
  computed: {
    ...mapGetters([
      'isNotesFetched',
      'discussions',
      'getNotesDataByProp',
      'discussionCount',
      'isLoading',
      'commentsDisabled',
    ]),
    noteableType() {
      return this.noteableData.noteableType;
    },
    allDiscussions() {
      if (this.isLoading) {
        const totalNotes = parseInt(this.notesData.totalNotes, 10) || 0;

        return new Array(totalNotes).fill({
          isSkeletonNote: true,
        });
      }

      return this.discussions;
    },
  },
  watch: {
    shouldShow() {
      if (!this.isNotesFetched) {
        this.fetchNotes();
      }
    },
  },
  created() {
    this.setNotesData(this.notesData);
    this.setNoteableData(this.noteableData);
    this.setUserData(this.userData);
    this.setTargetNoteHash(getLocationHash());
    eventHub.$once('fetchNotesData', this.fetchNotes);
  },
  mounted() {
    if (this.shouldShow) {
      this.fetchNotes();
    }

    const { parentElement } = this.$el;
    if (parentElement && parentElement.classList.contains('js-vue-notes-event')) {
      parentElement.addEventListener('toggleAward', event => {
        const { awardName, noteId } = event.detail;
        this.actionToggleAward({ awardName, noteId });
      });
    }
  },
  updated() {
    this.$nextTick(() => highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member')));
  },
  methods: {
    ...mapActions({
      setLoadingState: 'setLoadingState',
      fetchDiscussions: 'fetchDiscussions',
      poll: 'poll',
      actionToggleAward: 'toggleAward',
      scrollToNoteIfNeeded: 'scrollToNoteIfNeeded',
      setNotesData: 'setNotesData',
      setNoteableData: 'setNoteableData',
      setUserData: 'setUserData',
      setLastFetchedAt: 'setLastFetchedAt',
      setTargetNoteHash: 'setTargetNoteHash',
      toggleDiscussion: 'toggleDiscussion',
      setNotesFetchedState: 'setNotesFetchedState',
      startTaskList: 'startTaskList',
    }),
    getComponentName(discussion) {
      if (discussion.isSkeletonNote) {
        return skeletonLoadingContainer;
      }
      if (discussion.isPlaceholderNote) {
        if (discussion.placeholderType === constants.SYSTEM_NOTE) {
          return placeholderSystemNote;
        }
        return placeholderNote;
      } else if (discussion.individual_note) {
        return discussion.notes[0].system ? systemNote : noteableNote;
      }

      return noteableDiscussion;
    },
    getComponentData(discussion) {
      return discussion.individual_note ? { note: discussion.notes[0] } : { discussion };
    },
    fetchNotes() {
      if (this.isFetching) return null;

      this.isFetching = true;

      return this.fetchDiscussions({ path: this.getNotesDataByProp('discussionsPath') })
        .then(() => {
          this.initPolling();
        })
        .then(() => {
          this.setLoadingState(false);
          this.setNotesFetchedState(true);
          eventHub.$emit('fetchedNotesData');
          this.isFetching = false;
        })
        .then(() => this.$nextTick())
        .then(() => this.startTaskList())
        .then(() => this.checkLocationHash())
        .catch(() => {
          this.setLoadingState(false);
          this.setNotesFetchedState(true);
          Flash('Something went wrong while fetching comments. Please try again.');
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
      const noteId = hash && hash.replace(/^note_/, '');

      if (noteId) {
        this.discussions.forEach(discussion => {
          if (discussion.notes) {
            discussion.notes.forEach(note => {
              if (`${note.id}` === `${noteId}`) {
                // FIXME: this modifies the store state without using a mutation/action
                Object.assign(discussion, { expanded: true });
              }
            });
          }
        });
      }
    },
  },
};
</script>

<template>
  <div v-show="shouldShow" id="notes">
    <ul id="notes-list" class="notes main-notes-list timeline">
      <component
        :is="getComponentName(discussion)"
        v-for="discussion in allDiscussions"
        :key="discussion.id"
        v-bind="getComponentData(discussion)"
      />
    </ul>

    <comment-form
      v-if="!commentsDisabled"
      :noteable-type="noteableType"
      :markdown-version="markdownVersion"
    />
  </div>
</template>
