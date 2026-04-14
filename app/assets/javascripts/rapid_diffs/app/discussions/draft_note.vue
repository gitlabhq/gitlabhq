<script>
import { GlBadge, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { gfm } from '~/vue_shared/directives/gfm';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';
import { updateNoteErrorMessage } from '~/notes/utils';
import NoteHeader from './note_header.vue';
import NoteBody from './note_body.vue';

export default {
  name: 'DraftNote',
  components: {
    GlBadge,
    NoteHeader,
    NoteBody,
    GlButton,
  },
  directives: {
    gfm,
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    store: { type: Object },
  },
  props: {
    draft: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDeleting: false,
      isSaving: false,
    };
  },
  methods: {
    async onDelete() {
      const confirmed = await confirmAction(__('Are you sure you want to delete this comment?'), {
        primaryBtnVariant: 'danger',
        primaryBtnText: __('Delete comment'),
      });
      if (!confirmed) return;
      this.isDeleting = true;
      try {
        await this.store.deleteDraft(this.draft);
      } catch (error) {
        createAlert({
          message: __('Something went wrong while deleting your note. Please try again.'),
          parent: this.$el,
        });
      } finally {
        this.isDeleting = false;
      }
    },
    async saveNote(noteText) {
      this.isSaving = true;
      try {
        await this.store.updateDraft({ note: this.draft, noteText });
        this.store.setEditingMode(this.draft, false);
      } catch (error) {
        createAlert({
          message: updateNoteErrorMessage(error),
          parent: this.$el,
        });
      } finally {
        this.isSaving = false;
      }
    },
    onCancelEditing() {
      this.store.setEditingMode(this.draft, false);
    },
    startEditing() {
      this.store.setEditingMode(this.draft, true);
    },
  },
};
</script>

<template>
  <div
    class="draft-note rd-draft-note gl-relative gl-bg-[var(--timeline-entry-draft-note-background-color)] gl-shadow-[0_0_0_1px_var(--gl-color-orange-400)]"
    :class="{ 'gl-pointer-events-none gl-opacity-5': isSaving || isDeleting }"
    data-testid="draft-note"
  >
    <div class="flash-container !gl-mt-0"></div>
    <div class="gl-flex gl-flex-wrap gl-items-start gl-justify-between gl-gap-2 gl-px-4 gl-pt-2">
      <note-header
        class="gl-my-1 gl-py-2"
        :author="draft.author"
        :created-at="draft.created_at"
        show-avatar
      >
        <template #badge>
          <gl-badge
            v-gl-tooltip:tooltipcontainer.bottom
            data-testid="draft-note-indicator"
            variant="warning"
            class="gl-ml-2"
            :title="__('Pending comments are hidden until you submit your review.')"
          >
            {{ __('Pending') }}
          </gl-badge>
        </template>
      </note-header>
      <div class="gl-flex gl-min-h-7 gl-flex-1 gl-items-center gl-justify-end gl-pt-1">
        <gl-button
          v-gl-tooltip
          :title="__('Edit comment')"
          :aria-label="__('Edit comment')"
          icon="pencil"
          category="tertiary"
          @click="startEditing"
        />
        <gl-button
          v-gl-tooltip
          :title="__('Delete comment')"
          :aria-label="__('Delete comment')"
          icon="remove"
          category="tertiary"
          @click="onDelete"
        />
      </div>
    </div>
    <div class="gl-ml-2 gl-pb-4 gl-pl-8 gl-pr-4">
      <!-- eslint-disable vue/v-on-event-hyphenation -->
      <note-body
        :note="draft"
        can-edit
        :is-editing="draft.isEditing"
        :save-note="saveNote"
        @cancelEditing="onCancelEditing"
      />
      <!-- eslint-enable vue/v-on-event-hyphenation -->
      <div
        v-if="!draft.isEditing && draft.references && draft.references.commands"
        v-gfm="draft.references.commands"
        class="gl-mb-2 gl-text-sm gl-text-subtle"
      ></div>
    </div>
  </div>
</template>
