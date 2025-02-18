<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { createAlert } from '~/alert';
import { clearDraft, getDraft, getAutoSaveKeyFromDiscussion } from '~/lib/utils/autosave';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { s__, __, sprintf } from '~/locale';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { FILE_DIFF_POSITION_TYPE, IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import eventHub from '../event_hub';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import { createNoteErrorMessages } from '../utils';
import DiffDiscussionHeader from './diff_discussion_header.vue';
import DiffWithNote from './diff_with_note.vue';
import DiscussionActions from './discussion_actions.vue';
import DiscussionNotes from './discussion_notes.vue';
import NoteForm from './note_form.vue';
import NoteSignedOutWidget from './note_signed_out_widget.vue';

export default {
  name: 'NoteableDiscussion',
  components: {
    GlIcon,
    UserAvatarLink,
    DiffDiscussionHeader,
    NoteSignedOutWidget,
    NoteForm,
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
    isOverviewTab: {
      type: Boolean,
      required: false,
      default: false,
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
    diffFile() {
      const diffFile = this.discussion.diff_file;
      if (!diffFile) return null;

      return {
        ...diffFile,
        view_path: window.location.href.replace(
          /\/-\/merge_requests.*/,
          `/-/blob/${diffFile.content_sha}/${diffFile.new_path}`,
        ),
      };
    },
    currentUser() {
      return this.getUserData;
    },
    isLoggedIn() {
      return isLoggedIn();
    },
    commentType() {
      return this.discussion.internal ? __('internal note') : __('comment');
    },
    autosaveKey() {
      return getAutoSaveKeyFromDiscussion(this.discussion);
    },
    newNotePath() {
      return this.getNoteableData.create_note_path;
    },
    saveButtonTitle() {
      return this.discussion.internal ? __('Reply internally') : __('Reply');
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
      return this.shouldRenderDiffs ? DiffWithNote : 'div';
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
      if (this.shouldRenderDiffs) {
        if (this.discussion.diff_file?.diff_refs) {
          return true;
        }

        /*
         * https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19118
         *
         * For most diff discussions we should have a `diff_file`.
         * However in some cases we might we might not have this object.
         * In these we need to check if the `original_position.position_type`
         * is either a file or an image, doing this allows us to still
         * render the reply actions.
         */
        return (
          this.discussion.original_position?.position_type === FILE_DIFF_POSITION_TYPE ||
          this.discussion.original_position?.position_type === IMAGE_DIFF_POSITION_TYPE
        );
      }

      return true;
    },
    isDiscussionInternal() {
      return this.discussion.notes[0]?.internal;
    },
    discussionHolderClass() {
      return {
        'is-replying': this.isReplying,
        'internal-note': this.isDiscussionInternal,
        '!gl-pt-0': !this.discussion.diff_discussion && this.isReplying,
      };
    },
    hasDraft() {
      return Boolean(getDraft(this.autosaveKey));
    },
  },
  created() {
    eventHub.$on('startReplying', this.onStartReplying);
    if (this.hasDraft) {
      this.showReplyForm();
    }
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
    showReplyForm(text) {
      this.isReplying = true;

      if (!this.discussion.expanded) {
        this.expandDiscussion({ discussionId: this.discussion.id });
      }

      if (typeof text !== 'undefined') {
        this.$nextTick(() => {
          this.$refs.noteForm.append(text);
        });
      }
    },
    cancelReplyForm: ignoreWhilePending(async function cancelReplyForm(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const msg = sprintf(
          s__('Notes|Are you sure you want to cancel creating this %{commentType}?'),
          { commentType: this.commentType },
        );

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
        });

        if (!confirmed) {
          return;
        }
      }

      if (this.convertedDisscussionIds.includes(this.discussion.id)) {
        this.removeConvertedDiscussion(this.discussion.id);
      }

      this.isReplying = false;
      clearDraft(this.autosaveKey);
    }),
    async saveReply(noteText, form, callback) {
      if (!noteText) {
        this.cancelReplyForm();
        callback();
        return;
      }

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) {
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
        .then(() => {
          this.isReplying = false;
          clearDraft(this.autosaveKey);

          callback();
        })
        .catch((err) => {
          this.handleSaveError(err); // The 'err' parameter is being used in JH, don't remove it
          this.removePlaceholderNotes();

          callback(err);
        });
    },
    handleSaveError({ response }) {
      const errorMessage = createNoteErrorMessages(response.data, response.status)[0];

      createAlert({
        message: errorMessage,
        parent: this.$el,
      });
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
        :data-discussion-resolvable="discussion.resolvable"
        :data-discussion-resolved="discussion.resolved"
        class="discussion js-discussion-container"
        data-testid="discussion-content"
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
              :is-overview-tab="isOverviewTab"
              @startReplying="showReplyForm"
            >
              <template #avatar-badge>
                <slot name="avatar-badge"></slot>
              </template>
              <template #footer="{ showReplies }">
                <draft-note
                  v-if="showDraft(discussion.reply_id)"
                  :key="`draft_${discussion.id}`"
                  :draft="draftForDiscussion(discussion.reply_id)"
                  :line="line"
                />
                <li
                  v-else-if="canShowReplyActions && showReplies"
                  data-testid="reply-wrapper"
                  class="discussion-reply-holder clearfix gl-bg-subtle"
                  :class="discussionHolderClass"
                >
                  <div class="flash-container !gl-mt-0 gl-mb-2"></div>
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
                    :diff-file="diffFile"
                    :line="diffLine"
                    :save-button-title="saveButtonTitle"
                    :autofocus="!hasDraft"
                    :autosave-key="autosaveKey"
                    @handleFormUpdateAddToReview="addReplyToReview"
                    @handleFormUpdate="saveReply"
                    @cancelForm="cancelReplyForm"
                  />
                  <note-signed-out-widget v-if="!isLoggedIn" />
                </li>
              </template>
            </discussion-notes>
          </component>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
