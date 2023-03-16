<script>
import { GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

export default {
  constantOptions: {
    markdownDocsPath: helpPagePath('user/markdown'),
  },
  components: {
    GlButton,
    MarkdownEditor,
  },
  inject: ['fullPath'],
  props: {
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
  },
  data() {
    return {
      commentText: getDraft(this.autosaveKey) || this.initialValue || '',
    };
  },
  computed: {
    markdownPreviewPath() {
      return joinPaths(
        '/',
        gon.relative_url_root || '',
        this.fullPath,
        `/preview_markdown?target_type=${this.workItemType}`,
      );
    },
    formFieldProps() {
      return {
        'aria-label': this.ariaLabel,
        placeholder: __('Write a comment or drag your files here…'),
        id: 'work-item-add-or-edit-comment',
        name: 'work-item-add-or-edit-comment',
      };
    },
  },
  methods: {
    setCommentText(newText) {
      this.commentText = newText;
      updateDraft(this.autosaveKey, this.commentText);
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
  <div class="timeline-content">
    <div class="timeline-discussion-body">
      <div class="note-body">
        <form class="common-note-form gfm-form js-main-target-form gl-flex-grow-1">
          <markdown-editor
            :value="commentText"
            :render-markdown-path="markdownPreviewPath"
            :markdown-docs-path="$options.constantOptions.markdownDocsPath"
            :form-field-props="formFieldProps"
            data-testid="work-item-add-comment"
            class="gl-mb-3"
            autofocus
            use-bottom-toolbar
            @input="setCommentText"
            @keydown.meta.enter="$emit('submitForm', commentText)"
            @keydown.ctrl.enter="$emit('submitForm', commentText)"
            @keydown.esc.stop="cancelEditing"
          />
          <gl-button
            category="primary"
            variant="confirm"
            data-testid="confirm-button"
            :loading="isSubmitting"
            @click="$emit('submitForm', commentText)"
            >{{ commentButtonText }}
          </gl-button>
          <gl-button
            data-testid="cancel-button"
            category="primary"
            class="gl-ml-3"
            @click="cancelEditing"
            >{{ __('Cancel') }}
          </gl-button>
        </form>
      </div>
    </div>
  </div>
</template>
