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
      isLoading: true,
    };
  },
  computed: {
    ...mapGetters(['isNotesFetched', 'discussions', 'getNotesDataByProp', 'discussionCount']),
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
  methods: {
    ...mapActions({
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
      return this.fetchDiscussions(this.getNotesDataByProp('discussionsPath'))
        .then(() => {
          this.initPolling();
        })
        .then(() => {
          this.isLoading = false;
          this.setNotesFetchedState(true);
          eventHub.$emit('fetchedNotesData');
        })
        .then(() => this.$nextTick())
        .then(() => this.checkLocationHash())
        .catch(() => {
          this.isLoading = false;
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
  <div
    v-show="shouldShow"
    id="notes"
  >
    <ul
      id="notes-list"
      class="notes main-notes-list timeline"
    >
      <component
        v-for="discussion in allDiscussions"
        v-if="!discussion.notes[0].system"
        :is="getComponentName(discussion)"
        v-bind="getComponentData(discussion)"
        :key="discussion.id"
      />
    </ul>

    <comment-form
      :noteable-type="noteableType"
      :markdown-version="markdownVersion"
    />
  </div>
</template>
