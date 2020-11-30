<script>
import $ from 'jquery';
import { mapGetters, mapActions } from 'vuex';
import { escape } from 'lodash';
import { GlSprintf, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { truncateSha } from '~/lib/utils/text_utility';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { __, s__, sprintf } from '../../locale';
import { deprecatedCreateFlash as Flash } from '../../flash';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import noteHeader from './note_header.vue';
import noteActions from './note_actions.vue';
import NoteBody from './note_body.vue';
import eventHub from '../event_hub';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
  commentLineOptions,
  formatLineRange,
} from './multiline_comment_utils';
import { INLINE_DIFF_LINES_KEY } from '~/diffs/constants';

export default {
  name: 'NoteableNote',
  components: {
    GlSprintf,
    userAvatarLink,
    noteHeader,
    noteActions,
    NoteBody,
    TimelineEntryItem,
  },
  directives: {
    SafeHtml,
  },
  mixins: [noteable, resolvable, glFeatureFlagsMixin()],
  props: {
    note: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    commit: {
      type: Object,
      required: false,
      default: () => null,
    },
    showReplyButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    diffLines: {
      type: Array,
      required: false,
      default: null,
    },
    discussionRoot: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussionResolvePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isEditing: false,
      isDeleting: false,
      isRequesting: false,
      isResolving: false,
      commentLineStart: {},
      resolveAsThread: this.glFeatures.removeResolveNote,
    };
  },
  computed: {
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters(['targetNoteHash', 'getNoteableData', 'getUserData', 'commentsDisabled']),
    author() {
      return this.note.author;
    },
    classNameBindings() {
      return {
        [`note-row-${this.note.id}`]: true,
        'is-editing': this.isEditing && !this.isRequesting,
        'is-requesting being-posted': this.isRequesting,
        'disabled-content': this.isDeleting,
        target: this.isTarget,
        'is-editable': this.note.current_user.can_edit,
      };
    },
    canReportAsAbuse() {
      return Boolean(this.note.report_abuse_path) && this.author.id !== this.getUserData.id;
    },
    noteAnchorId() {
      return `note_${this.note.id}`;
    },
    isTarget() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    discussionId() {
      if (this.discussion) {
        return this.discussion.id;
      }
      return '';
    },
    actionText() {
      if (!this.commit) {
        return '';
      }

      // We need to do this to ensure we have the correct sentence order
      // when translating this as the sentence order may change from one
      // language to the next. See:
      // https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/24427#note_133713771
      const { id, url } = this.commit;
      const commitLink = `<a class="commit-sha monospace" href="${escape(url)}">${truncateSha(
        id,
      )}</a>`;
      return sprintf(s__('MergeRequests|commented on commit %{commitLink}'), { commitLink }, false);
    },
    isDraft() {
      return this.note.isDraft;
    },
    canResolve() {
      if (this.glFeatures.removeResolveNote && !this.discussionRoot) return false;

      if (this.glFeatures.removeResolveNote) return this.note.current_user.can_resolve_discussion;

      return (
        this.note.current_user.can_resolve ||
        (this.note.isDraft && this.note.discussion_id !== null)
      );
    },
    lineRange() {
      return this.note.position?.line_range;
    },
    startLineNumber() {
      return getStartLineNumber(this.lineRange);
    },
    endLineNumber() {
      return getEndLineNumber(this.lineRange);
    },
    showMultiLineComment() {
      if (
        !this.glFeatures.multilineComments ||
        !this.discussionRoot ||
        this.startLineNumber.length === 0 ||
        this.endLineNumber.length === 0
      )
        return false;

      return this.line && this.startLineNumber !== this.endLineNumber;
    },
    commentLineOptions() {
      const lines = this.diffFile[INLINE_DIFF_LINES_KEY].length;
      return commentLineOptions(lines, this.commentLineStart, this.line.line_code);
    },
    diffFile() {
      if (this.commentLineStart.line_code) {
        const lineCode = this.commentLineStart.line_code.split('_')[0];
        return this.getDiffFileByHash(lineCode);
      }

      return null;
    },
  },
  created() {
    const line = this.note.position?.line_range?.start || this.line;

    this.commentLineStart = line
      ? {
          line_code: line.line_code,
          type: line.type,
          old_line: line.old_line,
          new_line: line.new_line,
        }
      : {};

    eventHub.$on('enterEditMode', ({ noteId }) => {
      if (noteId === this.note.id) {
        this.isEditing = true;
        this.setSelectedCommentPositionHover();
        this.scrollToNoteIfNeeded($(this.$el));
      }
    });
  },

  mounted() {
    if (this.isTarget) {
      this.scrollToNoteIfNeeded($(this.$el));
    }
  },

  methods: {
    ...mapActions([
      'deleteNote',
      'removeNote',
      'updateNote',
      'toggleResolveNote',
      'scrollToNoteIfNeeded',
      'updateAssignees',
      'setSelectedCommentPositionHover',
      'updateDiscussionPosition',
    ]),
    editHandler() {
      this.isEditing = true;
      this.setSelectedCommentPositionHover();
      this.$emit('handleEdit');
    },
    deleteHandler() {
      const typeOfComment = this.note.isDraft ? __('pending comment') : __('comment');
      if (
        // eslint-disable-next-line no-alert
        window.confirm(
          sprintf(__('Are you sure you want to delete this %{typeOfComment}?'), { typeOfComment }),
        )
      ) {
        this.isDeleting = true;
        this.$emit('handleDeleteNote', this.note);

        if (this.note.isDraft) return;

        this.deleteNote(this.note)
          .then(() => {
            this.isDeleting = false;
          })
          .catch(() => {
            Flash(__('Something went wrong while deleting your note. Please try again.'));
            this.isDeleting = false;
          });
      }
    },
    updateSuccess() {
      this.isEditing = false;
      this.isRequesting = false;
      this.oldContent = null;
      $(this.$refs.noteBody.$el).renderGFM();
      this.$refs.noteBody.resetAutoSave();
      this.$emit('updateSuccess');
    },
    formUpdateHandler(noteText, parentElement, callback, resolveDiscussion) {
      const position = {
        ...this.note.position,
      };

      if (this.discussionRoot && this.commentLineStart && this.line) {
        position.line_range = formatLineRange(this.commentLineStart, this.line);
        this.updateDiscussionPosition({
          discussionId: this.note.discussion_id,
          position,
        });
      }

      this.$emit('handleUpdateNote', {
        note: this.note,
        noteText,
        resolveDiscussion,
        position,
        callback: () => this.updateSuccess(),
      });

      if (this.isDraft) return;

      const data = {
        endpoint: this.note.path,
        note: {
          target_type: this.getNoteableData.targetType,
          target_id: this.note.noteable_id,
          note: { note: noteText, position: JSON.stringify(position) },
        },
      };
      this.isRequesting = true;
      this.oldContent = this.note.note_html;
      this.note.note_html = escape(noteText);

      this.updateNote(data)
        .then(() => {
          this.updateSuccess();
          callback();
        })
        .catch(response => {
          if (response.status === httpStatusCodes.GONE) {
            this.removeNote(this.note);
            this.updateSuccess();
            callback();
          } else {
            this.isRequesting = false;
            this.isEditing = true;
            this.setSelectedCommentPositionHover();
            this.$nextTick(() => {
              const msg = __('Something went wrong while editing your comment. Please try again.');
              Flash(msg, 'alert', this.$el);
              this.recoverNoteContent(noteText);
              callback();
            });
          }
        });
    },
    formCancelHandler(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        // eslint-disable-next-line no-alert
        if (!window.confirm(__('Are you sure you want to cancel editing this comment?'))) return;
      }
      this.$refs.noteBody.resetAutoSave();
      if (this.oldContent) {
        this.note.note_html = this.oldContent;
        this.oldContent = null;
      }
      this.isEditing = false;
      this.$emit('cancelForm');
    },
    recoverNoteContent(noteText) {
      // we need to do this to prevent noteForm inconsistent content warning
      // this is something we intentionally do so we need to recover the content
      this.note.note = noteText;
      const { noteBody } = this.$refs;
      if (noteBody) {
        noteBody.note.note = noteText;
      }
    },
    getLineClasses(lineNumber) {
      return getLineClasses(lineNumber);
    },
    assigneesUpdate(assignees) {
      this.updateAssignees(assignees);
    },
  },
};
</script>

<template>
  <timeline-entry-item
    :id="noteAnchorId"
    :class="classNameBindings"
    :data-award-url="note.toggle_award_path"
    :data-note-id="note.id"
    class="note note-wrapper"
    data-qa-selector="noteable_note_container"
  >
    <div
      v-if="showMultiLineComment"
      data-testid="multiline-comment"
      class="gl-mb-3 gl-text-gray-500 gl-border-gray-200 gl-border-b-solid gl-border-b-1 gl-pb-3"
    >
      <gl-sprintf :message="__('Comment on lines %{startLine} to %{endLine}')">
        <template #startLine>
          <span :class="getLineClasses(startLineNumber)">{{ startLineNumber }}</span>
        </template>
        <template #endLine>
          <span :class="getLineClasses(endLineNumber)">{{ endLineNumber }}</span>
        </template>
      </gl-sprintf>
    </div>
    <div class="timeline-icon">
      <user-avatar-link
        :link-href="author.path"
        :img-src="author.avatar_url"
        :img-alt="author.name"
        :img-size="40"
      >
        <slot slot="avatar-badge" name="avatar-badge"></slot>
      </user-avatar-link>
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <note-header
          :author="author"
          :created-at="note.created_at"
          :note-id="note.id"
          :is-confidential="note.confidential"
        >
          <slot slot="note-header-info" name="note-header-info"></slot>
          <span v-if="commit" v-safe-html="actionText"></span>
          <span v-else-if="note.created_at" class="d-none d-sm-inline">&middot;</span>
        </note-header>
        <note-actions
          :author="author"
          :author-id="author.id"
          :note-id="note.id"
          :note-url="note.noteable_note_url"
          :access-level="note.human_access"
          :is-contributor="note.is_contributor"
          :is-author="note.is_noteable_author"
          :project-name="note.project_name"
          :noteable-type="note.noteable_type"
          :show-reply="showReplyButton"
          :can-edit="note.current_user.can_edit"
          :can-award-emoji="note.current_user.can_award_emoji"
          :can-delete="note.current_user.can_edit"
          :can-report-as-abuse="canReportAsAbuse"
          :can-resolve="canResolve"
          :report-abuse-path="note.report_abuse_path"
          :resolvable="note.resolvable || note.isDraft"
          :is-resolved="note.resolved || note.resolve_discussion"
          :is-resolving="isResolving"
          :resolved-by="note.resolved_by"
          :is-draft="note.isDraft"
          :resolve-discussion="note.isDraft && note.resolve_discussion"
          :discussion-id="discussionId"
          @handleEdit="editHandler"
          @handleDelete="deleteHandler"
          @handleResolve="resolveHandler"
          @startReplying="$emit('startReplying')"
          @updateAssignees="assigneesUpdate"
        />
      </div>
      <div class="timeline-discussion-body">
        <slot name="discussion-resolved-text"></slot>
        <note-body
          ref="noteBody"
          :note="note"
          :line="line"
          :can-edit="note.current_user.can_edit"
          :is-editing="isEditing"
          :help-page-path="helpPagePath"
          @handleFormUpdate="formUpdateHandler"
          @cancelForm="formCancelHandler"
        />
      </div>
    </div>
  </timeline-entry-item>
</template>
