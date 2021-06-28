<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import createFlash from '~/flash';
import { clearDraft, getDiscussionReplyKey } from '~/lib/utils/autosave';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import eventHub from '../event_hub';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import diffDiscussionHeader from './diff_discussion_header.vue';
import diffWithNote from './diff_with_note.vue';
import DiscussionActions from './discussion_actions.vue';
import DiscussionNotes from './discussion_notes.vue';
import noteForm from './note_form.vue';
import noteSignedOutWidget from './note_signed_out_widget.vue';

export default {
  name: 'NoteableDiscussion',
  components: {
    GlIcon,
    userAvatarLink,
    diffDiscussionHeader,
    noteSignedOutWidget,
    noteForm,
    DraftNote,
    TimelineEntryItem,
    DiscussionNotes,
    DiscussionActions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [noteable, resolvable, diffLineNoteFormMixin],
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    renderDiffFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    alwaysExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussionsByDiffOrder: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isReplying: false,
      isResolving: false,
      resolveAsThread: true,
    };
  },
  computed: {
    ...mapGetters([
      'convertedDisscussionIds',
      'getNoteableData',
      'userCanReply',
      'showJumpToNextDiscussion',
      'getUserData',
    ]),
    currentUser() {
      return this.getUserData;
    },
    isLoggedIn() {
      return isLoggedIn();
    },
    autosaveKey() {
      return getDiscussionReplyKey(this.firstNote.noteable_type, this.discussion.id);
    },
    newNotePath() {
      return this.getNoteableData.create_note_path;
    },
    firstNote() {
      return this.discussion.notes.slice(0, 1)[0];
    },
    shouldShowJumpToNextDiscussion() {
      return this.showJumpToNextDiscussion(this.discussionsByDiffOrder ? 'diff' : 'discussion');
    },
    shouldRenderDiffs() {
      return this.discussion.diff_discussion && this.renderDiffFile;
    },
    shouldGroupReplies() {
      return !this.shouldRenderDiffs;
    },
    wrapperComponent() {
      return this.shouldRenderDiffs ? diffWithNote : 'div';
    },
    wrapperComponentProps() {
      if (this.shouldRenderDiffs) {
        return { discussion: this.discussion };
      }

      return {};
    },
    isExpanded() {
      return this.discussion.expanded || this.alwaysExpanded;
    },
    shouldHideDiscussionBody() {
      return this.shouldRenderDiffs && !this.isExpanded;
    },
    diffLine() {
      if (this.line) {
        return this.line;
      }

      if (this.discussion.diff_discussion && this.discussion.truncated_diff_lines) {
        return this.discussion.truncated_diff_lines.slice(-1)[0];
      }

      return null;
    },
    resolveWithIssuePath() {
      return !this.discussionResolved ? this.discussion.resolve_with_issue_path : '';
    },
    canShowReplyActions() {
      if (this.shouldRenderDiffs && !this.discussion.diff_file.diff_refs) {
        return false;
      }

      return true;
    },
  },
  created() {
    eventHub.$on('startReplying', this.onStartReplying);
  },
  beforeDestroy() {
    eventHub.$off('startReplying', this.onStartReplying);
  },
  methods: {
    ...mapActions([
      'saveNote',
      'removePlaceholderNotes',
      'toggleResolveNote',
      'removeConvertedDiscussion',
      'expandDiscussion',
    ]),
    showReplyForm() {
      this.isReplying = true;

      if (!this.discussion.expanded) {
        this.expandDiscussion({ discussionId: this.discussion.id });
      }
    },
    cancelReplyForm(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const msg = s__('Notes|Are you sure you want to cancel creating this comment?');

        // eslint-disable-next-line no-alert
        if (!window.confirm(msg)) {
          return;
        }
      }

      if (this.convertedDisscussionIds.includes(this.discussion.id)) {
        this.removeConvertedDiscussion(this.discussion.id);
      }

      this.isReplying = false;
      clearDraft(this.autosaveKey);
    },
    saveReply(noteText, form, callback) {
      if (!noteText) {
        this.cancelReplyForm();
        callback();
        return;
      }
      const postData = {
        in_reply_to_discussion_id: this.discussion.reply_id,
        target_type: this.getNoteableData.targetType,
        note: { note: noteText },
      };

      if (this.convertedDisscussionIds.includes(this.discussion.id)) {
        postData.return_discussion = true;
      }

      if (this.discussion.for_commit) {
        postData.note_project_id = this.discussion.project_id;
      }

      const replyData = {
        endpoint: this.newNotePath,
        flashContainer: this.$el,
        data: postData,
      };

      this.saveNote(replyData)
        .then((res) => {
          if (res.hasFlash !== true) {
            this.isReplying = false;
            clearDraft(this.autosaveKey);
          }
          callback();
        })
        .catch((err) => {
          this.removePlaceholderNotes();
          const msg = __(
            'Your comment could not be submitted! Please check your network connection and try again.',
          );
          createFlash({
            message: msg,
            parent: this.$el,
          });
          this.$refs.noteForm.note = noteText;
          callback(err);
        });
    },
    deleteNoteHandler(note) {
      this.$emit('noteDeleted', this.discussion, note);
    },
    onStartReplying(discussionId) {
      if (this.discussion.id === discussionId) {
        this.showReplyForm();
      }
    },
  },
};
</script>

<template>
  <timeline-entry-item class="note note-discussion">
    <div class="timeline-content">
      <div
        :data-discussion-id="discussion.id"
        class="discussion js-discussion-container"
        data-qa-selector="discussion_content"
      >
        <diff-discussion-header v-if="shouldRenderDiffs" :discussion="discussion" />
        <div v-if="!shouldHideDiscussionBody" class="discussion-body">
          <component
            :is="wrapperComponent"
            v-bind="wrapperComponentProps"
            class="card discussion-wrapper"
          >
            <discussion-notes
              :discussion="discussion"
              :diff-line="diffLine"
              :help-page-path="helpPagePath"
              :is-expanded="isExpanded"
              :line="line"
              :should-group-replies="shouldGroupReplies"
              @startReplying="showReplyForm"
              @deleteNote="deleteNoteHandler"
            >
              <template #avatar-badge>
                <slot name="avatar-badge"></slot>
              </template>
              <template #footer="{ showReplies }">
                <draft-note
                  v-if="showDraft(discussion.reply_id)"
                  :key="`draft_${discussion.id}`"
                  :draft="draftForDiscussion(discussion.reply_id)"
                />
                <div
                  v-else-if="canShowReplyActions && showReplies"
                  :class="{ 'is-replying': isReplying }"
                  class="discussion-reply-holder gl-border-t-0! clearfix"
                >
                  <discussion-actions
                    v-if="!isReplying && userCanReply"
                    :discussion="discussion"
                    :is-resolving="isResolving"
                    :resolve-button-title="resolveButtonTitle"
                    :resolve-with-issue-path="resolveWithIssuePath"
                    :should-show-jump-to-next-discussion="shouldShowJumpToNextDiscussion"
                    @showReplyForm="showReplyForm"
                    @resolve="resolveHandler"
                  />
                  <note-form
                    v-if="isReplying"
                    ref="noteForm"
                    :discussion="discussion"
                    :is-editing="false"
                    :line="diffLine"
                    save-button-title="Comment"
                    :autosave-key="autosaveKey"
                    @handleFormUpdateAddToReview="addReplyToReview"
                    @handleFormUpdate="saveReply"
                    @cancelForm="cancelReplyForm"
                  />
                  <note-signed-out-widget v-if="!isLoggedIn" />
                </div>
              </template>
            </discussion-notes>
          </component>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
