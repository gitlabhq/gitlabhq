<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { noSpacesRegex } from '~/lib/utils/regexp';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import editModelMutation from '../graphql/mutations/edit_model.mutation.graphql';
import { MODEL_EDIT_MODAL_ID } from '../constants';

export default {
  name: 'ModelEdit',
  components: {
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlModal,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['projectPath', 'maxAllowedFileSize', 'markdownPreviewPath'],
  props: {
    model: {
      type: Object,
      required: true,
    },
    disableAttachments: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      errorMessage: null,
      modelData: null,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
      description: this.model.description,
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    modelNameIsValid() {
      return this.model.name && noSpacesRegex.test(this.model.name);
    },
    submitButtonDisabled() {
      return !this.modelNameIsValid;
    },
    actionPrimary() {
      return {
        text: s__('MlModelRegistry|Save changes'),
        attributes: { variant: 'confirm', disabled: this.submitButtonDisabled },
      };
    },
    modelNameDescription() {
      return !this.model.name || this.modelNameIsValid ? this.$options.modal.nameDescription : '';
    },
  },
  methods: {
    async edit($event) {
      $event.preventDefault();

      this.errorMessage = '';
      try {
        const { data } = await this.$apollo.mutate({
          mutation: editModelMutation,
          variables: {
            projectPath: this.projectPath,
            modelId: getIdFromGraphQLId(this.model.id),
            name: this.model.name,
            description: this.description,
          },
        });
        const modelErrors = data?.mlModelEdit?.errors || [];
        if (modelErrors.length) {
          this.errorMessage = modelErrors.join(', ');
        } else {
          const { showPath } = data.mlModelEdit.model._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
      }
    },
    resetModal() {
      this.name = null;
      this.modelData = null;
      this.description = null;
      this.errorMessage = null;
    },
    hideAlert() {
      this.errorMessage = null;
    },
    setDescription(newText) {
      if (!this.isSubmitting) {
        this.description = newText;
      }
    },
  },
  i18n: {},
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model description'),
    id: 'model-description',
    name: 'model-description',
  },
  modal: {
    id: MODEL_EDIT_MODAL_ID,
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
    nameDescriptionLabel: s__('MlModelRegistry|Must be unique. May not contain spaces.'),
    nameDescription: s__('MlModelRegistry|Example: my-model'),
    nameInvalid: s__('MlModelRegistry|May not contain spaces.'),
    nameDescriptionPlaceholder: s__('MlModelRegistry|Enter a model description'),
    editButtonLabel: s__('MlModelRegistry|Edit model'),
    title: s__('MlModelRegistry|Edit model'),
    modelName: s__('MlModelRegistry|Model name'),
    modelDescription: __('Model description'),
    optionalText: s__('MlModelRegistry|(Optional)'),
  },
};
</script>

<template>
  <div>
    <gl-button v-gl-modal="$options.modal.id">{{ $options.modal.editButtonLabel }}</gl-button>
    <gl-modal
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="lg"
      @primary="edit"
      @secondary="resetModal"
    >
      <gl-form>
        <gl-form-group
          :label="$options.modal.modelName"
          :label-description="$options.modal.nameDescriptionLabel"
          label-for="nameId"
          data-testid="nameGroupId"
          :state="modelNameIsValid"
          :invalid-feedback="$options.modal.nameInvalid"
          :description="modelNameDescription"
        >
          <gl-form-input
            id="nameId"
            :value="model.name"
            data-testid="nameId"
            type="text"
            :disabled="true"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.modal.modelDescription"
          data-testid="descriptionGroupId"
          label-for="descriptionId"
          optional
          :optional-text="$options.modal.optionalText"
          class="common-note-form gfm-form js-main-target-form new-note gl-grow"
        >
          <markdown-editor
            ref="markdownEditor"
            data-testid="descriptionId"
            :value="model.description"
            enable-autocomplete
            :autocomplete-data-sources="autocompleteDataSources"
            :enable-content-editor="true"
            :form-field-props="$options.descriptionFormFieldProps"
            :render-markdown-path="markdownPreviewPath"
            :markdown-docs-path="markdownDocPath"
            :disable-attachments="disableAttachments"
            :placeholder="$options.modal.nameDescriptionPlaceholder"
            :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
            @input="setDescription"
          />
        </gl-form-group>
      </gl-form>

      <gl-alert
        v-if="errorMessage"
        data-testid="modalEditAlert"
        variant="danger"
        @dismiss="hideAlert"
        >{{ errorMessage }}
      </gl-alert>
    </gl-modal>
  </div>
</template>
