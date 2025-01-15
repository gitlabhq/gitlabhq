<script>
import { GlSprintf, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { escape } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions } from 'vuex';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { INLINE_DIFF_LINES_KEY } from '~/diffs/constants';
import { createAlert } from '~/alert';
import { HTTP_STATUS_GONE } from '~/lib/utils/http_status';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { truncateSha } from '~/lib/utils/text_utility';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { __, s__, sprintf } from '~/locale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import eventHub from '../event_hub';
import noteable from '../mixins/noteable';
import resolvable from '../mixins/resolvable';
import { renderMarkdown, updateNoteErrorMessage } from '../utils';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
  commentLineOptions,
} from './multiline_comment_utils';
import NoteActions from './note_actions.vue';
import NoteBody from './note_body.vue';
import NoteHeader from './note_header.vue';

export default {
  name: 'NoteableNote',
  components: {
    GlSprintf,
    NoteHeader,
    NoteActions,
    NoteBody,
    TimelineEntryItem,
    GlAvatarLink,
    GlAvatar,
  },
  directives: {
    SafeHtml,
  },
  mixins: [noteable, resolvable],
  inject: {
    reportAbusePath: {
      default: '',
    },
  },
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
    discussionFile: {
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
    isOverviewTab: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussion: {
      type: Object,
      required: false,
      default: null,
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
    restoreFromAutosave: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditingLocal: false,
      isDeleting: false,
      isRequesting: false,
      isResolving: false,
      commentLineStart: {},
      resolveAsThread: true,
    };
  },
  computed: {
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters(['targetNoteHash', 'getNoteableData', 'getUserData', 'commentsDisabled']),
    isEditing: {
      get() {
        return this.note.isEditing ?? this.isEditingLocal;
      },
      set(value) {
        this.isEditingLocal = value;
        if (value) {
          this.$emit('handleEdit');
        } else {
          this.$emit('cancelForm');
        }
      },
    },
    author() {
      return this.note.author;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    commentType() {
      return this.note.internal ? __('internal note') : __('comment');
    },
    classNameBindings() {
      return {
        [`note-row-${this.note.id}`]: true,
        'is-editing': this.isEditing && !this.isRequesting,
        'is-requesting being-posted': this.isRequesting,
        'disabled-content': this.isDeleting,
        target: this.isTarget,
        'is-editable': this.canEdit,
      };
    },
    canAwardEmoji() {
      return this.note.current_user?.can_award_emoji ?? false;
    },
    canEdit() {
      return this.note.current_user?.can_edit ?? false;
    },
    canReportAsAbuse() {
      return Boolean(this.reportAbusePath) && this.authorId !== this.getUserData.id;
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
      if (!this.discussionRoot) return false;
      if (!this.note.resolvable) return false;

      return this.note.current_user?.can_resolve_discussion;
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
      let fileResolvedFromAvailableSource;

      if (this.commentLineStart.line_code) {
        const lineCode = this.commentLineStart.line_code.split('_')[0];
        fileResolvedFromAvailableSource = this.getDiffFileByHash(lineCode);
      }

      if (!fileResolvedFromAvailableSource && this.discussionFile) {
        fileResolvedFromAvailableSource = this.discussionFile;
      }

      return fileResolvedFromAvailableSource || null;
    },
    isMRDiffView() {
      const isFileComment = this.note.position?.position_type === 'file';
      return !this.isOverviewTab && (this.line || isFileComment);
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
        this.$el.scrollIntoView();
      }
    });
  },

  methods: {
    ...mapActions([
      'deleteNote',
      'removeNote',
      'updateNote',
      'toggleResolveNote',
      'updateAssignees',
      'setSelectedCommentPositionHover',
    ]),
    editHandler() {
      this.isEditing = true;
      this.setSelectedCommentPositionHover();
    },
    async deleteHandler() {
      let { commentType } = this;

      if (this.note.isDraft) {
        // Draft internal notes (i.e. MR review comments) are not supported.
        commentType = __('pending comment');
      }

      const msg = sprintf(__('Are you sure you want to delete this %{commentType}?'), {
        commentType,
      });
      const confirmed = await confirmAction(msg, {
        primaryBtnVariant: 'danger',
        primaryBtnText: this.note.internal ? __('Delete internal note') : __('Delete comment'),
      });

      if (confirmed) {
        this.isDeleting = true;
        this.$emit('handleDeleteNote', this.note);

        if (this.note.isDraft) return;

        this.deleteNote(this.note)
          .then(() => {
            this.isDeleting = false;
          })
          .catch(() => {
            createAlert({
              message: __('Something went wrong while deleting your note. Please try again.'),
            });
            this.isDeleting = false;
          });
      }
    },
    updateSuccess() {
      this.isEditingLocal = false;
      this.isRequesting = false;
      this.oldContent = null;
      renderGFM(this.$refs.noteBody.$el);
      this.$emit('updateSuccess');
    },
    async formUpdateHandler({ noteText, callback, resolveDiscussion }) {
      this.$emit('handleUpdateNote', {
        note: this.note,
        noteText,
        resolveDiscussion,
        flashContainer: this.$el,
        callback: () => this.updateSuccess(),
        errorCallback: () => callback(),
      });

      if (this.isDraft) return;

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: noteText });

      if (!confirmSubmit) {
        callback();
        return;
      }

      const data = {
        endpoint: this.note.path,
        note: {
          target_type: this.getNoteableData.targetType,
          target_id: this.note.noteable_id,
          note: { note: noteText },
        },
      };

      this.isRequesting = true;
      this.oldContent = this.note.note_html;
      // eslint-disable-next-line vue/no-mutating-props
      this.note.note_html = renderMarkdown(noteText);

      this.updateNote(data)
        .then(() => {
          this.updateSuccess();
          callback();
        })
        .catch((e) => {
          if (e.status === HTTP_STATUS_GONE) {
            this.removeNote(this.note);
            this.updateSuccess();
            callback();
          } else {
            this.isRequesting = false;
            this.isEditing = true;
            this.setSelectedCommentPositionHover();
            this.$nextTick(() => {
              this.handleUpdateError(e); // The 'e' parameter is being used in JH, don't remove it
              this.recoverNoteContent();
              callback();
            });
          }
        });
    },
    handleUpdateError(e) {
      createAlert({
        message: updateNoteErrorMessage(e),
        parent: this.$el,
      });
    },
    formCancelHandler: ignoreWhilePending(async function formCancelHandler({
      shouldConfirm,
      isDirty,
    }) {
      if (shouldConfirm && isDirty) {
        const msg = sprintf(__('Are you sure you want to cancel editing this %{commentType}?'), {
          commentType: this.commentType,
        });
        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Cancel editing'),
          primaryBtnVariant: 'danger',
          secondaryBtnVariant: 'default',
          secondaryBtnText: __('Continue editing'),
          hideCancel: true,
        });
        if (!confirmed) return;
      }
      this.recoverNoteContent();
      this.isEditing = false;
    }),
    recoverNoteContent() {
      if (this.oldContent) {
        // eslint-disable-next-line vue/no-mutating-props
        this.note.note_html = this.oldContent;
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
    :class="{ ...classNameBindings, 'internal-note': note.internal }"
    :data-award-url="note.toggle_award_path"
    :data-note-id="note.id"
    class="note note-wrapper note-comment"
    data-testid="noteable-note-container"
  >
    <div
      v-if="showMultiLineComment"
      data-testid="multiline-comment"
      class="gl-border-b gl-border-section gl-px-5 gl-py-3 gl-text-subtle"
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

    <div v-if="isMRDiffView" class="timeline-avatar gl-float-left gl-pt-2">
      <gl-avatar-link
        :href="author.path"
        :data-user-id="authorId"
        :data-username="author.username"
        class="js-user-link"
      >
        <gl-avatar
          :src="author.avatar_url"
          :entity-name="author.username"
          :alt="author.name"
          :size="24"
        />

        <slot name="avatar-badge"></slot>
      </gl-avatar-link>
    </div>

    <div v-else class="timeline-avatar gl-float-left">
      <gl-avatar-link
        :href="author.path"
        :data-user-id="authorId"
        :data-username="author.username"
        class="js-user-link gl-relative"
      >
        <gl-avatar
          :src="author.avatar_url"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />

        <slot name="avatar-badge"></slot>
      </gl-avatar-link>
    </div>

    <div class="timeline-content">
      <div class="note-header">
        <note-header
          :author="author"
          :created-at="note.created_at"
          :note-id="note.id"
          :is-internal-note="note.internal"
          :is-imported="note.imported"
          :noteable-type="noteableType"
          :email-participant="note.external_author"
        >
          <template #note-header-info>
            <slot name="note-header-info"></slot>
          </template>
          <span v-if="commit" v-safe-html="actionText"></span>
          <span v-else-if="note.created_at" class="gl-hidden sm:gl-inline">&middot;</span>
        </note-header>
        <note-actions
          :author="author"
          :author-id="authorId"
          :note-id="note.id"
          :note-url="note.noteable_note_url"
          :access-level="note.human_access"
          :is-contributor="note.is_contributor"
          :is-author="note.is_noteable_author"
          :project-name="note.project_name"
          :noteable-type="note.noteable_type"
          :show-reply="showReplyButton"
          :can-edit="canEdit"
          :can-award-emoji="canAwardEmoji"
          :can-delete="canEdit"
          :can-report-as-abuse="canReportAsAbuse"
          :can-resolve="canResolve"
          :resolvable="note.resolvable || note.isDraft"
          :is-resolved="note.resolved || note.resolve_discussion"
          :is-resolving="isResolving"
          :resolved-by="note.resolved_by"
          :is-draft="note.isDraft"
          :resolve-discussion="note.isDraft && note.resolve_discussion"
          :discussion-id="discussionId"
          :award-path="note.toggle_award_path"
          @handleEdit="editHandler"
          @handleDelete="deleteHandler"
          @handleResolve="resolveHandler"
          @startReplying="$emit('startReplying')"
          @updateAssignees="assigneesUpdate"
        />
      </div>
      <div class="timeline-discussion-body">
        <slot name="discussion-resolved-text"></slot>
        <slot name="note-body">
          <note-body
            ref="noteBody"
            :note="note"
            :can-edit="canEdit"
            :line="line"
            :file="diffFile"
            :is-editing="isEditing"
            :autosave-key="autosaveKey"
            :restore-from-autosave="restoreFromAutosave"
            :help-page-path="helpPagePath"
            @handleFormUpdate="formUpdateHandler"
            @cancelForm="formCancelHandler"
          />
        </slot>
        <div class="timeline-discussion-body-footer">
          <slot name="after-note-body"></slot>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
