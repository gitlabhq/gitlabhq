<script>
import { GlBadge, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { createAlert } from '~/alert';
import { useBatchComments } from '~/batch_comments/store';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { sprintf, __ } from '~/locale';
import NoteForm from '~/notes/components/note_form.vue';
import { useNotes } from '~/notes/store/legacy_notes';
import { updateNoteErrorMessage } from '~/notes/utils';
import LineRangeHeadline from '~/rapid_diffs/app/discussions/line_range_headline.vue';
import resolvedStatusMixin from '../mixins/resolved_status';

export default {
  name: 'PreviewItem',
  components: {
    GlBadge,
    GlButton,
    LineRangeHeadline,
    NoteForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [resolvedStatusMixin],
  props: {
    draft: {
      type: Object,
      required: true,
    },
  },
  emits: ['click'],
  data() {
    return {
      isEditing: false,
      isDeleting: false,
    };
  },
  computed: {
    ...mapState(useNotes, ['getDiscussion']),
    discussion() {
      return this.getDiscussion(this.draft.discussion_id);
    },
    isDiffDiscussion() {
      return this.discussion && this.discussion.diff_discussion;
    },
    filePath() {
      const file = this.discussion ? this.discussion.diff_file : this.draft;

      return file?.file_path;
    },
    threadTitle() {
      return sprintf(
        __("Reply to %{authorsName}'s thread"),
        {
          authorsName: this.discussion.notes.find((note) => !note.system).author.name,
        },
        false,
      );
    },
    showLinePosition() {
      return this.draft.file_hash || this.isDiffDiscussion;
    },
    position() {
      return this.draft.position || this.discussion.position;
    },
    imagePositionText() {
      if (this.position?.position_type !== IMAGE_DIFF_POSITION_TYPE) return null;

      return sprintf(__('Comment on image at %{x}x %{y}y'), this.position);
    },
    saveButtonTitle() {
      return this.draft.internal ? __('Save internal note') : __('Save comment');
    },
  },
  watch: {
    'draft.note_html': {
      async handler() {
        await this.$nextTick();
        renderGFM(this.$refs.noteBody);
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(useBatchComments, ['updateDraft', 'deleteDraft']),
    async onDelete() {
      const confirmed = await confirmAction(
        __('Are you sure you want to delete this pending comment?'),
        { primaryBtnVariant: 'danger', primaryBtnText: __('Delete comment') },
      );
      if (!confirmed) return;

      this.isDeleting = true;
      await this.deleteDraft(this.draft);
      this.isDeleting = false;
    },
    // eslint-disable-next-line max-params
    async onFormUpdate(noteText, parentElement, callback, resolveDiscussion) {
      try {
        await this.updateDraft({ note: this.draft, noteText, resolveDiscussion });
        this.stopEditing();
      } catch (error) {
        createAlert({
          message: updateNoteErrorMessage(error),
          parent: this.$el,
          captureError: true,
          error,
        });
        callback();
      }
    },
    async onFormCancel(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const confirmed = await confirmAction(
          sprintf(__('Are you sure you want to cancel editing this %{commentType}?'), {
            commentType: this.draft.internal ? __('internal note') : __('comment'),
          }),
          {
            primaryBtnText: __('Cancel editing'),
            primaryBtnVariant: 'danger',
            secondaryBtnVariant: 'default',
            secondaryBtnText: __('Continue editing'),
            hideCancel: true,
          },
        );
        if (!confirmed) return;
      }
      this.stopEditing();
    },
    async stopEditing() {
      this.isEditing = false;
      await this.$nextTick();
      this.$refs.editButton.$el.focus();
    },
  },
  showStaysResolved: false,
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>

<template>
  <div class="pending-review-item gl-relative gl-flex gl-gap-3 gl-pb-4">
    <div class="gl-flex gl-w-6 gl-shrink-0 gl-justify-center gl-pt-5">
      <div
        class="system-note-dot gl-relative gl-h-3 gl-w-3 gl-rounded-full gl-border-2 gl-border-solid gl-border-subtle"
      ></div>
    </div>
    <div class="file-holder gl-min-w-0 gl-grow gl-overflow-hidden gl-border-section">
      <div
        class="gl-border-b gl-flex gl-items-center gl-gap-3 gl-border-section"
        :class="{
          'file-title file-title-flex-parent !gl-flex-nowrap': filePath,
          'gl-bg-section gl-px-5 gl-py-3': !filePath,
        }"
      >
        <gl-button
          v-if="filePath"
          variant="link"
          class="gl-min-w-0 !gl-justify-start !gl-text-default"
          button-text-classes="!gl-whitespace-normal gl-text-left"
          data-testid="preview-item-header"
          @click="$emit('click', draft)"
        >
          <strong
            class="file-title-name gl-break-all"
            data-testid="review-preview-item-header-text"
            >{{ filePath }}</strong
          >
        </gl-button>
        <gl-button
          v-else-if="discussion"
          variant="link"
          class="gl-min-w-0 !gl-text-subtle"
          button-text-classes="!gl-whitespace-normal gl-text-left"
          data-testid="preview-item-header"
          @click="$emit('click', draft)"
        >
          <span data-testid="review-preview-item-header-text">{{ threadTitle }}</span>
        </gl-button>
        <span v-else class="gl-text-subtle" data-testid="review-preview-item-header-text">
          {{ __('Direct comment') }}
        </span>
        <div class="gl-ml-auto gl-flex gl-shrink-0 gl-items-center gl-gap-2">
          <gl-badge
            v-if="draft.internal"
            v-gl-tooltip
            variant="warning"
            data-testid="internal-note-indicator"
            :title="s__('Notes|This internal note will always remain confidential')"
          >
            {{ __('Internal note') }}
          </gl-badge>
          <template v-if="draft.current_user.can_edit">
            <gl-button
              ref="editButton"
              v-gl-tooltip
              :title="__('Edit comment')"
              :aria-label="__('Edit comment')"
              icon="pencil"
              category="tertiary"
              size="small"
              class="note-action-button"
              :disabled="isEditing"
              data-testid="preview-item-edit"
              @click="isEditing = true"
            />
            <gl-button
              v-gl-tooltip
              :title="__('Delete comment')"
              :aria-label="__('Delete comment')"
              icon="remove"
              category="tertiary"
              size="small"
              class="note-action-button"
              :loading="isDeleting"
              :disabled="isEditing"
              data-testid="preview-item-delete"
              @click="onDelete"
            />
          </template>
        </div>
      </div>
      <div
        v-if="showLinePosition && imagePositionText"
        class="gl-border-b gl-border-section gl-bg-section gl-px-5 gl-py-3 gl-text-subtle"
        data-testid="preview-item-image-position"
      >
        {{ imagePositionText }}
      </div>
      <line-range-headline
        v-else-if="showLinePosition"
        :line-range="position.line_range"
        class="gl-border-b gl-border-section gl-bg-section gl-px-5 gl-py-3 gl-text-subtle"
      />
      <div class="gl-bg-section gl-px-3 gl-py-2">
        <note-form
          v-if="isEditing"
          class="gl-p-3"
          :note-body="draft.note"
          :note-id="draft.id"
          :note="draft"
          :discussion="discussion"
          :resolve-discussion="draft.resolve_discussion"
          :save-button-title="saveButtonTitle"
          is-draft
          @handle-form-update="onFormUpdate"
          @cancel-form="onFormCancel"
        />
        <div v-show="!isEditing" ref="noteBody" class="gl-px-3 gl-py-3">
          <div
            v-safe-html:[$options.safeHtmlConfig]="draft.note_html"
            class="note-text md"
            data-testid="review-preview-item-content"
          ></div>
          <gl-badge
            v-if="draft.discussion_id && resolvedStatusMessage"
            class="gl-mt-3"
            data-testid="draft-note-resolution"
            variant="info"
            icon="status_success"
            icon-optically-aligned
          >
            {{ resolvedStatusMessage }}
          </gl-badge>
        </div>
      </div>
    </div>
  </div>
</template>
