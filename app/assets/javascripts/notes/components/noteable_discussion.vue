<script>
import { mapActions, mapGetters } from 'vuex';
import { GlTooltipDirective } from '@gitlab/ui';
import diffLineNoteFormMixin from 'ee_else_ce/notes/mixins/diff_line_note_form';
import { s__, __ } from '~/locale';
import { clearDraft, getDiscussionReplyKey } from '~/lib/utils/autosave';
import icon from '~/vue_shared/components/icon.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import Flash from '../../flash';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import diffDiscussionHeader from './diff_discussion_header.vue';
import noteSignedOutWidget from './note_signed_out_widget.vue';
import noteForm from './note_form.vue';
import diffWithNote from './diff_with_note.vue';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import discussionNavigation from '../mixins/discussion_navigation';
import eventHub from '../event_hub';
import DiscussionNotes from './discussion_notes.vue';
import DiscussionActions from './discussion_actions.vue';

export default {
  name: 'NoteableDiscussion',
  components: {
    icon,
    userAvatarLink,
    diffDiscussionHeader,
    noteSignedOutWidget,
    noteForm,
    DraftNote: () => import('ee_component/batch_comments/components/draft_note.vue'),
    TimelineEntryItem,
    DiscussionNotes,
    DiscussionActions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [noteable, resolvable, discussionNavigation, diffLineNoteFormMixin],
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
      'nextUnresolvedDiscussionId',
      'unresolvedDiscussionsCount',
      'hasUnresolvedDiscussions',
      'showJumpToNextDiscussion',
      'getUserData',
      'getDiscussion',
    ]),
    currentUser() {
      return this.getUserData;
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
      'expandDiscussion',
      'removeConvertedDiscussion',
    ]),
    showReplyForm() {
      this.isReplying = true;
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
        .then(res => {
          if (res.hasFlash !== true) {
            this.isReplying = false;
            clearDraft(this.autosaveKey);
          }
          callback();
        })
        .catch(err => {
          this.removePlaceholderNotes();
          const msg = __(
            'Your comment could not be submitted! Please check your network connection and try again.',
          );
          Flash(msg, 'alert', this.$el);
          this.$refs.noteForm.note = noteText;
          callback(err);
        });
    },
    jumpToNextDiscussion() {
      const nextId = this.nextUnresolvedDiscussionId(
        this.discussion.id,
        this.discussionsByDiffOrder,
      );
      const nextDiscussion = this.getDiscussion(nextId);

      this.jumpToDiscussion(nextDiscussion);
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
              <slot slot="avatar-badge" name="avatar-badge"></slot>
              <template #footer="{ showReplies }">
                <draft-note
                  v-if="showDraft(discussion.reply_id)"
                  :key="`draft_${discussion.id}`"
                  :draft="draftForDiscussion(discussion.reply_id)"
                />
                <div
                  v-else-if="showReplies"
                  :class="{ 'is-replying': isReplying }"
                  class="discussion-reply-holder clearfix"
                >
                  <user-avatar-link
                    v-if="!isReplying && userCanReply"
                    :link-href="currentUser.path"
                    :img-src="currentUser.avatar_url"
                    :img-alt="currentUser.name"
                    :img-size="40"
                    class="d-none d-sm-block"
                  />
                  <discussion-actions
                    v-if="!isReplying && userCanReply"
                    :discussion="discussion"
                    :is-resolving="isResolving"
                    :resolve-button-title="resolveButtonTitle"
                    :resolve-with-issue-path="resolveWithIssuePath"
                    :should-show-jump-to-next-discussion="shouldShowJumpToNextDiscussion"
                    @showReplyForm="showReplyForm"
                    @resolve="resolveHandler"
                    @jumpToNextDiscussion="jumpToNextDiscussion"
                  />
                  <div v-if="isReplying" class="avatar-note-form-holder">
                    <user-avatar-link
                      v-if="currentUser"
                      :link-href="currentUser.path"
                      :img-src="currentUser.avatar_url"
                      :img-alt="currentUser.name"
                      :img-size="40"
                      class="d-none d-sm-block"
                    />
                    <note-form
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
                  </div>
                  <note-signed-out-widget v-if="!userCanReply" />
                </div>
              </template>
            </discussion-notes>
          </component>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
