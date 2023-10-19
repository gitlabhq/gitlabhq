<script>
import { GlButton, GlFormGroup, GlAlert, GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { toggleMarkCheckboxes } from '~/behaviors/markdown/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import updateDesignDescriptionMutation from '../../graphql/mutations/update_design_description.mutation.graphql';
import { UPDATE_DESCRIPTION_ERROR } from '../../utils/error_messages';

const isCheckbox = (target) => target?.classList.contains('task-list-item-checkbox');

export default {
  components: {
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlFormGroup,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    edit: __('Edit'),
    editDescription: s__('DesignManagement|Edit description'),
    descriptionLabel: s__('DesignManagement|Design description'),
  },
  formFieldProps: {
    id: 'design-description',
    name: 'design-description',
    placeholder: s__('DesignManagement|Write a comment or drag your files here…'),
    'aria-label': s__('DesignManagement|Design description'),
  },
  markdownDocsPath: helpPagePath('user/markdown'),
  quickActionsDocsPath: helpPagePath('user/project/quick_actions'),
  props: {
    design: {
      type: Object,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    designVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      descriptionText: this.design.description || '',
      showEditor: false,
      isSubmitting: false,
      errorMessage: '',
      autosaveKey: `Issue/${getIdFromGraphQLId(this.design.issue.id)}/Design/${getIdFromGraphQLId(
        this.design.id,
      )}`,
    };
  },
  computed: {
    canUpdate() {
      return this.design.issue?.userPermissions?.updateDesign && !this.showEditor;
    },
  },
  watch: {
    'design.descriptionHtml': {
      handler(newDescriptionHtml, oldDescriptionHtml) {
        if (newDescriptionHtml !== oldDescriptionHtml) {
          this.renderGFM();
        }
      },
      immediate: true,
    },
  },
  methods: {
    startEditing() {
      this.showEditor = true;
    },
    closeForm() {
      this.showEditor = false;
    },
    async renderGFM() {
      await this.$nextTick();
      renderGFM(this.$refs['gfm-content']);

      if (this.canUpdate) {
        const checkboxes = this.$el.querySelectorAll('.task-list-item-checkbox');

        // enable boxes, disabled by default in markdown
        checkboxes.forEach((checkbox) => {
          // eslint-disable-next-line no-param-reassign
          checkbox.disabled = false;
        });
      }
    },
    setDescriptionText(newText) {
      // Do not update when cmd+enter is executed
      if (!this.isSubmitting) {
        this.descriptionText = newText;
      }
    },
    async updateDesignDescription() {
      this.isSubmitting = true;

      if (this.$refs.markdownEditor) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        trackSavedUsingEditor(this.$refs.markdownEditor.isContentEditorActive, 'Design');
      }

      try {
        const designDescriptionInput = { description: this.descriptionText, id: this.design.id };

        await this.$apollo.mutate({
          mutation: updateDesignDescriptionMutation,
          variables: {
            input: designDescriptionInput,
          },
        });

        this.closeForm();
      } catch {
        this.errorMessage = UPDATE_DESCRIPTION_ERROR;
      } finally {
        this.isSubmitting = false;
      }
    },
    toggleCheckboxes(event) {
      const { target } = event;

      if (isCheckbox(target)) {
        target.disabled = true;

        const { sourcepos } = target.parentElement.dataset;

        if (!sourcepos) return;

        // Toggle checkboxes based on user input
        this.descriptionText = toggleMarkCheckboxes({
          rawMarkdown: this.descriptionText,
          checkboxChecked: target.checked,
          sourcepos,
        });

        // Update the desciption text using mutation
        this.updateDesignDescription();
      }
    },
  },
};
</script>

<template>
  <div class="design-description-container">
    <gl-form-group
      v-if="showEditor"
      class="design-description-form common-note-form"
      :label="$options.i18n.descriptionLabel"
    >
      <div v-if="errorMessage" class="gl-pb-3">
        <gl-alert variant="danger" @dismiss="errorMessage = null">
          {{ errorMessage }}
        </gl-alert>
      </div>
      <markdown-editor
        ref="markdownEditor"
        :value="descriptionText"
        :render-markdown-path="markdownPreviewPath"
        :markdown-docs-path="$options.markdownDocsPath"
        :form-field-props="$options.formFieldProps"
        :quick-actions-docs-path="$options.quickActionsDocsPath"
        :autosave-key="autosaveKey"
        enable-autocomplete
        :supports-quick-actions="false"
        autofocus
        @input="setDescriptionText"
        @keydown.meta.enter="updateDesignDescription"
        @keydown.ctrl.enter="updateDesignDescription"
        @keydown.exact.esc.stop="closeForm"
      />
      <div class="gl-display-flex gl-mt-3">
        <gl-button
          category="primary"
          variant="confirm"
          :loading="isSubmitting"
          data-testid="save-description"
          @click="updateDesignDescription"
          >{{ s__('DesignManagement|Save') }}
        </gl-button>
        <gl-button category="tertiary" class="gl-ml-3" data-testid="cancel" @click="closeForm"
          >{{ s__('DesignManagement|Cancel') }}
        </gl-button>
      </div>
    </gl-form-group>
    <div v-else class="design-description-view">
      <div
        class="design-description-header gl-display-flex gl-justify-content-space-between gl-mb-2"
      >
        <label class="gl-m-0">
          {{ $options.i18n.descriptionLabel }}
        </label>
        <gl-button
          v-if="canUpdate"
          v-gl-tooltip
          class="gl-ml-auto"
          size="small"
          data-testid="edit-description"
          :aria-label="$options.i18n.editDescription"
          @click="startEditing"
        >
          {{ $options.i18n.edit }}
        </gl-button>
      </div>
      <div
        v-if="!design.descriptionHtml"
        data-testid="design-description-none"
        class="gl-text-secondary gl-mb-5"
      >
        {{ s__('DesignManagement|None') }}
      </div>
      <div v-else class="design-description js-task-list-container">
        <div
          ref="gfm-content"
          v-safe-html="design.descriptionHtml"
          class="md gl-mb-4"
          data-testid="design-description-content"
          @change="toggleCheckboxes"
        ></div>
      </div>
    </div>
  </div>
</template>
