<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions } from 'vuex';
import { v4 as uuidv4 } from 'uuid';
import { InternalEvents } from '~/tracking';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_NOTE } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getDraft, getAutoSaveKeyFromDiscussion } from '~/lib/utils/autosave';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { getLocationHash } from '~/lib/utils/url_utility';
import PlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import PlaceholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';
import SkeletonLoadingContainer from '~/vue_shared/components/notes/skeleton_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import { Mousetrap } from '~/lib/mousetrap';
import { ISSUABLE_COMMENT_OR_REPLY, keysFor } from '~/behaviors/shortcuts/keybindings';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import * as constants from '../constants';
import eventHub from '../event_hub';
import noteQuery from '../graphql/note.query.graphql';
import CommentForm from './comment_form.vue';
import DiscussionFilterNote from './discussion_filter_note.vue';
import NoteableDiscussion from './noteable_discussion.vue';
import NoteableNote from './noteable_note.vue';
import OrderedLayout from './ordered_layout.vue';
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
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
  provide() {
    return {
      summarizeClientSubscriptionId: uuidv4(),
    };
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
      previewNote: null,
    };
  },
  apollo: {
    previewNote: {
      skip() {
        const notCommentId = Boolean(this.previewNoteId?.match(/([a-f0-9]{40})/));
        return !this.previewNoteId || notCommentId;
      },
      query: noteQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_NOTE, this.previewNoteId),
        };
      },
      update(data) {
        if (!data?.note?.discussion) return null;
        return {
          id: `${getIdFromGraphQLId(data.note.discussion.id)}`,
          expanded: true,
          notes: data.note.discussion.notes.nodes.map((note) => ({
            ...note,
            id: `${getIdFromGraphQLId(note.id)}`,
            author: {
              ...note.author,
              id: getIdFromGraphQLId(note.author.id),
            },
            award_emoji: note.award_emoji.nodes.map((emoji) => ({
              ...emoji,
              id: getIdFromGraphQLId(emoji.id),
              user: {
                ...emoji.user,
                id: getIdFromGraphQLId(emoji.user.id),
              },
            })),
            current_user: {
              can_award_emoji: note.userPermissions.awardEmoji,
              can_edit: note.userPermissions.adminNote,
              can_resolve_discussions: note.userPermissions.resolveNote,
            },
            last_edited_by: {
              ...note.last_edited_by,
              id: getIdFromGraphQLId(note.last_edited_by?.id),
            },
            toggle_award_path: '',
          })),
        };
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
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
      'targetNoteHash',
    ]),
    sortDirDesc() {
      return this.sortDirection === constants.DESC;
    },
    noteableType() {
      return this.noteableData.noteableType;
    },
    previewNoteId() {
      if (!this.isLoading || !this.targetNoteHash?.startsWith('note_')) return null;
      return this.targetNoteHash.replace('note_', '');
    },
    allDiscussions() {
      let skeletonNotes = [];

      if (this.renderSkeleton || this.isLoading) {
        const prerenderedNotesCount = parseInt(this.notesData.prerenderedNotesCount, 10) || 0;

        skeletonNotes = new Array(prerenderedNotesCount).fill({
          isSkeletonNote: true,
        });

        if (
          this.previewNote &&
          !this.discussions.find((d) => d.notes[0].id === this.previewNoteId)
        ) {
          skeletonNotes.splice(prerenderedNotesCount / 2, 0, this.previewNote);
        }
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
          this.cleanup?.();
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

    eventHub.$on('noteFormAddToReview', this.handleReviewTracking);
    eventHub.$on('noteFormStartReview', this.handleReviewTracking);

    window.addEventListener('hashchange', this.handleHashChanged);

    if (this.targetNoteHash && this.targetNoteHash.startsWith('note_')) {
      this.cleanup = scrollToTargetOnResize();
    }

    eventHub.$on('notesApp.updateIssuableConfidentiality', this.setConfidentiality);
    Mousetrap.bind(keysFor(ISSUABLE_COMMENT_OR_REPLY), (e) => this.quoteReply(e));
  },
  updated() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
    });
  },
  beforeDestroy() {
    window.removeEventListener('hashchange', this.handleHashChanged);
    eventHub.$off('notesApp.updateIssuableConfidentiality', this.setConfidentiality);
    eventHub.$off('noteFormStartReview', this.handleReviewTracking);
    eventHub.$off('noteFormAddToReview', this.handleReviewTracking);
    Mousetrap.unbind(keysFor(ISSUABLE_COMMENT_OR_REPLY), this.quoteReply);
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
      'setConfidentiality',
      'fetchNotes',
    ]),
    getDiscussionInSelection() {
      const selection = window.getSelection();
      if (selection.rangeCount <= 0) return null;

      const el = selection.getRangeAt(0).startContainer;
      const node = el.nodeType === Node.TEXT_NODE ? el.parentNode : el;
      return node.closest('.js-noteable-discussion');
    },
    async quoteReply(e) {
      const discussionEl = this.getDiscussionInSelection();
      const text = await CopyAsGFM.selectionToGfm();

      // Prevent 'r' being written.
      if (e && typeof e.preventDefault === 'function') {
        e.preventDefault();
      }

      if (!discussionEl) {
        this.replyInMainEditor(text);
      } else {
        const instance = this.$refs.discussions.find(({ $el }) => $el === discussionEl);
        // prevent hotkey input from going into the form
        requestAnimationFrame(() => {
          instance.showReplyForm(text);
        });
      }
    },
    replyInMainEditor(text) {
      this.$refs.commentForm.append(text);
    },
    discussionIsIndividualNoteAndNotConverted(discussion) {
      return (
        discussion.individual_note &&
        !this.convertedDisscussionIds.includes(discussion.id) &&
        !this.hasDraft(discussion)
      );
    },
    handleHashChanged() {
      const noteId = this.checkLocationHash();

      if (noteId) {
        this.setTargetNoteHash(getLocationHash());
      }
    },
    checkLocationHash() {
      const hash = getLocationHash();
      const noteId = (hash && hash.startsWith('note_') && hash.replace(/^note_/, '')) ?? null;

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
    handleReviewTracking(event) {
      const types = {
        noteFormStartReview: 'merge_request_click_start_review_on_overview_tab',
        noteFormAddToReview: 'merge_request_click_add_to_review_on_overview_tab',
      };

      if (this.shouldShow && window.mrTabs && types[event.name]) {
        this.trackEvent(types[event.name]);
      }
    },
    hasDraft(discussion) {
      const autoSaveKey = getAutoSaveKeyFromDiscussion(discussion);
      return Boolean(getDraft(autoSaveKey));
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
    <ai-summary v-if="aiLoading !== null" :ai-loading="aiLoading" @set-ai-loading="setAiLoading" />
    <ordered-layout :slot-keys="slotKeys">
      <template #form>
        <comment-form
          v-if="!(commentsDisabled || timelineEnabled)"
          ref="commentForm"
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
              ref="discussions"
              :key="discussion.id"
              class="js-noteable-discussion"
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
