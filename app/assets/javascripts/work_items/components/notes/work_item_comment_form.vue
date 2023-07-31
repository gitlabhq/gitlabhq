<script>
import { GlButton, GlFormCheckbox, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { STATE_OPEN, TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import WorkItemStateToggleButton from '~/work_items/components/work_item_state_toggle_button.vue';

export default {
  i18n: {
    internal: s__('Notes|Make this an internal note'),
    internalVisibility: s__(
      'Notes|Internal notes are only visible to members with the role of Reporter or higher',
    ),
    addInternalNote: __('Add internal note'),
    cancelButtonText: __('Cancel'),
  },
  constantOptions: {
    markdownDocsPath: helpPagePath('user/markdown'),
  },
  components: {
    GlButton,
    MarkdownEditor,
    GlFormCheckbox,
    GlIcon,
    WorkItemStateToggleButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    ariaLabel: {
      type: String,
      required: true,
    },
    autosaveKey: {
      type: String,
      required: true,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialValue: {
      type: String,
      required: false,
      default: '',
    },
    commentButtonText: {
      type: String,
      required: false,
      default: __('Comment'),
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isNewDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemState: {
      type: String,
      required: false,
      default: STATE_OPEN,
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      commentText: getDraft(this.autosaveKey) || this.initialValue || '',
      updateInProgress: false,
      isNoteInternal: false,
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'work_item_task_status',
        property: `type_${this.workItemType}`,
      };
    },
    formFieldProps() {
      return {
        'aria-label': this.ariaLabel,
        placeholder: __('Write a comment or drag your files here…'),
        id: 'work-item-add-or-edit-comment',
        name: 'work-item-add-or-edit-comment',
      };
    },
    isWorkItemOpen() {
      return this.workItemState === STATE_OPEN;
    },
    commentButtonTextComputed() {
      return this.isNoteInternal ? this.$options.i18n.addInternalNote : this.commentButtonText;
    },
  },
  methods: {
    setCommentText(newText) {
      /**
       * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
       *
       * While the form is saving using meta+enter,
       * avoid updating the data which is cleared after form submission.
       */
      if (!this.isSubmitting) {
        this.commentText = newText;
        updateDraft(this.autosaveKey, this.commentText);
      }
    },
    async cancelEditing() {
      if (this.commentText && this.commentText !== this.initialValue) {
        const msg = s__('WorkItem|Are you sure you want to cancel editing?');

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
          primaryBtnVariant: 'danger',
        });

        if (!confirmed) {
          return;
        }
      }

      this.$emit('cancelEditing');
      clearDraft(this.autosaveKey);
    },
  },
};
</script>

<template>
  <div class="timeline-discussion-body gl-overflow-visible!">
    <div class="note-body gl-p-0! gl-overflow-visible!">
      <form class="common-note-form gfm-form js-main-target-form gl-flex-grow-1">
        <markdown-editor
          :value="commentText"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="$options.constantOptions.markdownDocsPath"
          :autocomplete-data-sources="autocompleteDataSources"
          :form-field-props="formFieldProps"
          :add-spacing-classes="false"
          data-testid="work-item-add-comment"
          class="gl-mb-5"
          use-bottom-toolbar
          supports-quick-actions
          :autofocus="autofocus"
          @input="setCommentText"
          @keydown.meta.enter="$emit('submitForm', { commentText, isNoteInternal })"
          @keydown.ctrl.enter="$emit('submitForm', { commentText, isNoteInternal })"
          @keydown.esc.stop="cancelEditing"
        />
        <gl-form-checkbox
          v-if="isNewDiscussion"
          v-model="isNoteInternal"
          class="gl-mb-2"
          data-testid="internal-note-checkbox"
        >
          {{ $options.i18n.internal }}
          <gl-icon
            v-gl-tooltip:tooltipcontainer.bottom
            name="question-o"
            :size="16"
            :title="$options.i18n.internalVisibility"
            class="gl-text-blue-500"
          />
        </gl-form-checkbox>
        <gl-button
          category="primary"
          variant="confirm"
          data-testid="confirm-button"
          :disabled="!commentText.length"
          :loading="isSubmitting"
          @click="$emit('submitForm', { commentText, isNoteInternal })"
          >{{ commentButtonTextComputed }}
        </gl-button>
        <work-item-state-toggle-button
          v-if="isNewDiscussion"
          class="gl-ml-3"
          :work-item-id="workItemId"
          :work-item-state="workItemState"
          :work-item-type="workItemType"
          can-update
          @error="$emit('error', $event)"
        />
        <gl-button
          v-else
          data-testid="cancel-button"
          category="primary"
          class="gl-ml-3"
          :loading="updateInProgress"
          @click="cancelEditing"
          >{{ $options.i18n.cancelButtonText }}
        </gl-button>
      </form>
    </div>
  </div>
</template>
