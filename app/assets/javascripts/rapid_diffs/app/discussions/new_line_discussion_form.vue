<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { clearDraft } from '~/lib/utils/autosave';
import LineRangeHeadline from './line_range_headline.vue';
import NoteForm from './note_form.vue';

export default {
  name: 'NewLineDiscussionForm',
  i18n: {
    editLineRange: s__('RapidDiffs|Edit line range'),
  },
  components: {
    GlButton,
    LineRangeHeadline,
    NoteForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    store: { type: Object },
    showWhitespace: { default: undefined },
    resolveCodeSuggestions: { default: null },
  },
  provide() {
    return {
      codeSuggestions: () => this.resolveCodeSuggestions?.(this.discussion),
    };
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    autosaveKey() {
      const {
        old_path: oldPath,
        new_path: newPath,
        old_line: oldLine,
        new_line: newLine,
      } = this.discussion.position;
      const path = oldPath === newPath ? oldPath : [oldPath, newPath].join('-');
      const line = oldLine === newLine ? oldLine : [oldLine, newLine].join('-');
      return `${window.location.pathname}-${[path, line].join('-')}`;
    },
    canEditLineRange() {
      return Boolean(this.store.startLineRangeEditing);
    },
    lineRange() {
      return this.discussion.position?.line_range;
    },
  },
  watch: {
    'discussion.shouldFocus': function focusOnRequest(shouldFocus) {
      if (!shouldFocus) return;
      this.$nextTick(() => {
        this.$el.querySelector('textarea')?.focus();
        this.store.setNewLineDiscussionFormAutofocus(this.discussion, false);
      });
    },
  },
  mounted() {
    this.store.setNewLineDiscussionFormAutofocus(this.discussion, false);
  },
  beforeDestroy() {
    clearDraft(this.autosaveKey);
  },
  methods: {
    cancelReplyForm: ignoreWhilePending(async function cancelReplyForm() {
      if (this.discussion.noteBody) {
        const confirmed = await confirmAction(
          __('Are you sure you want to cancel creating this comment?'),
          {
            primaryBtnText: __('Discard changes'),
            cancelBtnText: __('Continue editing'),
          },
        );

        if (!confirmed) return;
      }

      clearDraft(this.autosaveKey);
      this.store.removeNewLineDiscussionForm(this.discussion);
    }),
    editLineRange() {
      this.store.startLineRangeEditing(this.discussion);
    },
    async saveNote(noteBody) {
      await this.store.createLineDiscussion({
        discussion: this.discussion,
        noteBody,
        showWhitespace: this.showWhitespace,
      });
    },
    async saveDraft(noteBody) {
      await this.store.createDraftLineDiscussion({
        discussion: this.discussion,
        noteBody,
        showWhitespace: this.showWhitespace,
      });
    },
  },
};
</script>

<template>
  <div
    class="gl-rounded-[var(--content-border-radius)] gl-bg-subtle gl-px-4 gl-py-4"
    :data-discussion-id="discussion.id"
  >
    <line-range-headline :line-range="lineRange" class="gl-mb-3 gl-text-sm gl-text-subtle">
      <gl-button
        v-if="canEditLineRange"
        v-gl-tooltip
        size="small"
        category="tertiary"
        icon="pencil"
        :title="$options.i18n.editLineRange"
        :aria-label="$options.i18n.editLineRange"
        data-testid="edit-line-range-button"
        @click="editLineRange"
      />
    </line-range-headline>
    <note-form
      :autosave-key="autosaveKey"
      :autofocus="discussion.shouldFocus"
      :note-body="discussion.noteBody"
      :save-button-title="__('Comment')"
      :save-note="saveNote"
      :save-draft="store.createDraftLineDiscussion ? saveDraft : null"
      :has-drafts="Boolean(store.hasDrafts)"
      @input="store.setDiscussionFormText(discussion, $event)"
      @cancel="cancelReplyForm"
    />
  </div>
</template>
