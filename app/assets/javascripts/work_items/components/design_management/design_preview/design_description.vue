<script>
import { GlButton, GlFormGroup, GlAlert, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { toggleMarkCheckboxes } from '~/behaviors/markdown/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import updateDesignDescriptionMutation from '../graphql/update_design_description.mutation.graphql';
import { UPDATE_DESCRIPTION_ERROR } from '../constants';

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
    editDescription: s__('DesignManagement|Edit description'),
    descriptionLabel: s__('DesignManagement|Description'),
    addDescriptionLabel: s__('DesignManagement|Add a description'),
    cancelEdit: s__('DesignManagement|Are you sure you want to cancel editing the description?'),
    primaryModalButton: s__('DesignManagement|Discard changes'),
    cancelModalButton: s__('DesignManagement|Continue editing'),
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
  },
  data() {
    return {
      descriptionText: this.design.description || '',
      showEditor: false,
      isSubmitting: false,
      errorMessage: '',
      autosaveKey: `WorkItem/${getIdFromGraphQLId(this.design.issue.id)}/Design/${getIdFromGraphQLId(
        this.design.id,
      )}`,
    };
  },
  computed: {
    canUpdate() {
      return this.design.issue?.userPermissions?.updateDesign && !this.showEditor;
    },
    showAddDescriptionButton() {
      return this.design.issue?.userPermissions?.updateDesign && !this.design.descriptionHtml;
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
      // If description text is empty on cancel,
      // restore the old description
      if (!this.descriptionText) {
        this.descriptionText = this.design.description;
      }
      this.showEditor = false;
    },
    async cancelDescription() {
      if (this.descriptionText && this.descriptionText !== this.design.description) {
        const confirmed = await confirmAction(this.$options.i18n.cancelEdit, {
          primaryBtnText: this.$options.i18n.primaryModalButton,
          cancelBtnText: this.$options.i18n.cancelModalButton,
          primaryBtnVariant: 'danger',
        });

        if (!confirmed) {
          return;
        }

        // Update markdown's placeholder text based on if
        // an existing description was being edited or
        // a totally new description was being added
        if (!this.design.descriptionHtml) {
          this.descriptionText = '';
        } else {
          this.descriptionText = this.design.description;
        }

        markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.autosaveKey);
        this.showEditor = false;
        this.enableCheckboxes();
      } else {
        this.descriptionText = this.design.description;
        this.showEditor = false;
        await this.$nextTick();
        this.enableCheckboxes();
      }
    },
    enableCheckboxes() {
      if (this.canUpdate) {
        const checkboxes = this.$el.querySelectorAll('.task-list-item-checkbox');

        // enable boxes, disabled by default in markdown
        checkboxes.forEach((checkbox) => {
          // eslint-disable-next-line no-param-reassign
          checkbox.disabled = false;
        });
      }
    },
    async renderGFM() {
      await this.$nextTick();
      renderGFM(this.$refs['gfm-content']);
      this.enableCheckboxes();
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
        const descriptionInput = { description: this.descriptionText, id: this.design.id };

        await this.$apollo.mutate({
          mutation: updateDesignDescriptionMutation,
          variables: {
            input: descriptionInput,
          },
        });

        this.closeForm();
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = UPDATE_DESCRIPTION_ERROR;
      } finally {
        await this.$nextTick();
        this.enableCheckboxes();
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
      label-class="!gl-leading-20 !gl-text-lg"
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
        @keydown.esc.stop="cancelDescription"
      />
      <div class="gl-mt-3 gl-flex">
        <gl-button
          category="primary"
          variant="confirm"
          :loading="isSubmitting"
          data-testid="save-description"
          @click="updateDesignDescription"
          >{{ s__('DesignManagement|Save changes') }}
        </gl-button>
        <gl-button
          category="tertiary"
          class="gl-ml-3"
          data-testid="cancel"
          @click="cancelDescription"
          >{{ s__('DesignManagement|Cancel') }}
        </gl-button>
      </div>
    </gl-form-group>
    <div v-else class="design-description-view">
      <gl-button
        v-if="showAddDescriptionButton"
        class="gl-mb-5 gl-ml-auto"
        size="small"
        data-testid="add-design-description"
        :aria-label="$options.i18n.addDescriptionLabel"
        @click="startEditing"
      >
        {{ $options.i18n.addDescriptionLabel }}
      </gl-button>
      <template v-else>
        <div class="design-description-header gl-mb-2 gl-flex gl-justify-between">
          <h3 class="gl-m-0 gl-text-lg !gl-leading-20">
            {{ $options.i18n.descriptionLabel }}
          </h3>
          <gl-button
            v-if="canUpdate"
            v-gl-tooltip
            class="gl-ml-auto"
            size="small"
            category="tertiary"
            :aria-label="$options.i18n.editDescription"
            :title="$options.i18n.editDescription"
            data-testid="edit-description"
            icon="pencil"
            @click="startEditing"
          />
        </div>
        <div v-if="design.descriptionHtml" class="design-description js-task-list-container">
          <div
            ref="gfm-content"
            v-safe-html="design.descriptionHtml"
            class="md gl-mb-4"
            data-testid="design-description-content"
            @change="toggleCheckboxes"
          ></div>
        </div>
      </template>
    </div>
  </div>
</template>
