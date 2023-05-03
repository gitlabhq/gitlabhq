<script>
import { mapGetters, mapActions } from 'vuex';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import OrderedLayout from '~/vue_shared/components/ordered_layout.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { getLocationHash } from '~/lib/utils/url_utility';
import PlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import PlaceholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';
import SkeletonLoadingContainer from '~/vue_shared/components/notes/skeleton_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import * as constants from '../constants';
import eventHub from '../event_hub';
import CommentForm from './comment_form.vue';
import DiscussionFilterNote from './discussion_filter_note.vue';
import NoteableDiscussion from './noteable_discussion.vue';
import NoteableNote from './noteable_note.vue';
import SidebarSubscription from './sidebar_subscription.vue';
import NotesActivityHeader from './notes_activity_header.vue';

export default {
  name: 'NotesApp',
  components: {
    NotesActivityHeader,
    NoteableNote,
    NoteableDiscussion,
    SystemNote,
    CommentForm,
    PlaceholderNote,
    PlaceholderSystemNote,
    SkeletonLoadingContainer,
    DiscussionFilterNote,
    OrderedLayout,
    SidebarSubscription,
    DraftNote,
    TimelineEntryItem,
    AiSummary: () => import('ee_component/notes/components/ai_summary.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    noteableData: {
      type: Object,
      required: true,
    },
    notesData: {
      type: Object,
      required: true,
    },
    notesFilters: {
      type: Array,
      required: true,
    },
    notesFilterValue: {
      type: Number,
      default: undefined,
      required: false,
    },
    shouldShow: {
      type: Boolean,
      required: false,
      default: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      currentFilter: null,
      renderSkeleton: !this.shouldShow,
      aiLoading: null,
      isInitialEventTriggered: false,
    };
  },
  computed: {
    ...mapGetters([
      'isNotesFetched',
      'discussions',
      'convertedDisscussionIds',
      'getNotesDataByProp',
      'isLoading',
      'isFetching',
      'commentsDisabled',
      'getNoteableData',
      'userCanReply',
      'sortDirection',
      'timelineEnabled',
    ]),
    sortDirDesc() {
      return this.sortDirection === constants.DESC;
    },
    noteableType() {
      return this.noteableData.noteableType;
    },
    allDiscussions() {
      let skeletonNotes = [];

      if (this.renderSkeleton || this.isLoading) {
        const prerenderedNotesCount = parseInt(this.notesData.prerenderedNotesCount, 10) || 0;

        skeletonNotes = new Array(prerenderedNotesCount).fill({
          isSkeletonNote: true,
        });
      }

      if (this.sortDirDesc) {
        return skeletonNotes.concat(this.discussions);
      }

      return this.discussions.concat(skeletonNotes);
    },
    canReply() {
      return this.userCanReply && !this.commentsDisabled && !this.timelineEnabled;
    },
    slotKeys() {
      return this.sortDirDesc ? ['form', 'comments'] : ['comments', 'form'];
    },
    isAppReady() {
      return !this.isLoading && !this.renderSkeleton && this.shouldShow;
    },
  },
  watch: {
    async isFetching() {
      if (!this.isFetching) {
        await this.$nextTick();
        await this.startTaskList();
        await this.checkLocationHash();
      }
    },
    shouldShow() {
      if (!this.isNotesFetched) {
        this.fetchNotes();
      }

      setTimeout(() => {
        this.renderSkeleton = !this.shouldShow;
      });
    },
    isAppReady: {
      handler(isReady) {
        if (!isReady) return;
        this.$nextTick(() => {
          window.mrTabs?.eventHub.$emit('NotesAppReady');
        });
      },
      immediate: true,
    },
  },
  mounted() {
    const { parentElement } = this.$el;
    if (parentElement && parentElement.classList.contains('js-vue-notes-event')) {
      parentElement.addEventListener('toggleAward', (event) => {
        const { awardName, noteId } = event.detail;
        this.toggleAward({ awardName, noteId });
      });
    }

    window.addEventListener('hashchange', this.handleHashChanged);

    eventHub.$on('notesApp.updateIssuableConfidentiality', this.setConfidentiality);
  },
  updated() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
    });
  },
  beforeDestroy() {
    this.stopPolling();
    window.removeEventListener('hashchange', this.handleHashChanged);
    eventHub.$off('notesApp.updateIssuableConfidentiality', this.setConfidentiality);
  },
  methods: {
    ...mapActions([
      'toggleAward',
      'setLastFetchedAt',
      'setTargetNoteHash',
      'toggleDiscussion',
      'expandDiscussion',
      'startTaskList',
      'convertToDiscussion',
      'stopPolling',
      'setConfidentiality',
      'fetchNotes',
    ]),
    discussionIsIndividualNoteAndNotConverted(discussion) {
      return discussion.individual_note && !this.convertedDisscussionIds.includes(discussion.id);
    },
    handleHashChanged() {
      const noteId = this.checkLocationHash();

      if (noteId) {
        this.setTargetNoteHash(getLocationHash());
      }
    },
    checkLocationHash() {
      const hash = getLocationHash();
      const noteId = hash && hash.replace(/^note_/, '');

      if (noteId) {
        const discussion = this.discussions.find((d) => d.notes.some(({ id }) => id === noteId));

        if (discussion) {
          this.expandDiscussion({ discussionId: discussion.id });
        }
      }

      return noteId;
    },
    startReplying(discussionId) {
      return this.convertToDiscussion(discussionId)
        .then(this.$nextTick)
        .then(() => eventHub.$emit('startReplying', discussionId));
    },
    setAiLoading(loading) {
      this.aiLoading = loading;
    },
  },
  systemNote: constants.SYSTEM_NOTE,
};
</script>

<template>
  <div v-show="shouldShow" id="notes">
    <sidebar-subscription :iid="noteableData.iid" :noteable-data="noteableData" />
    <notes-activity-header
      :notes-filters="notesFilters"
      :notes-filter-value="notesFilterValue"
      :ai-loading="aiLoading"
      @set-ai-loading="setAiLoading"
    />
    <ai-summary v-if="aiLoading !== null" @set-ai-loading="setAiLoading" />
    <ordered-layout :slot-keys="slotKeys">
      <template #form>
        <comment-form
          v-if="!(commentsDisabled || timelineEnabled)"
          class="js-comment-form"
          :noteable-type="noteableType"
        />
      </template>
      <template #comments>
        <ul id="notes-list" class="notes main-notes-list timeline">
          <template v-for="discussion in allDiscussions">
            <skeleton-loading-container
              v-if="discussion.isSkeletonNote"
              :key="discussion.id"
              class="note-skeleton"
            />
            <timeline-entry-item v-else-if="discussion.isDraft" :key="discussion.id">
              <draft-note :draft="discussion" />
            </timeline-entry-item>
            <template v-else-if="discussion.isPlaceholderNote">
              <placeholder-system-note
                v-if="discussion.placeholderType === $options.systemNote"
                :key="discussion.id"
                :note="discussion.notes[0]"
              />
              <placeholder-note v-else :key="discussion.id" :note="discussion.notes[0]" />
            </template>
            <template v-else-if="discussionIsIndividualNoteAndNotConverted(discussion)">
              <system-note
                v-if="discussion.notes[0].system"
                :key="discussion.id"
                :note="discussion.notes[0]"
              />
              <noteable-note
                v-else
                :key="discussion.id"
                :note="discussion.notes[0]"
                :show-reply-button="canReply"
                @startReplying="startReplying(discussion.id)"
              />
            </template>
            <noteable-discussion
              v-else
              :key="discussion.id"
              :discussion="discussion"
              :render-diff-file="true"
              is-overview-tab
              :help-page-path="helpPagePath"
            />
          </template>
          <discussion-filter-note v-if="commentsDisabled" />
        </ul>
      </template>
    </ordered-layout>
  </div>
</template>
