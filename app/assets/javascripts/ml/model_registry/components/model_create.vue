<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { semverRegex, noSpacesRegex } from '~/lib/utils/regexp';
import { uploadModel } from '../services/upload_model';
import createModelVersionMutation from '../graphql/mutations/create_model_version.mutation.graphql';
import createModelMutation from '../graphql/mutations/create_model.mutation.graphql';
import { emptyArtifactFile, MODEL_CREATION_MODAL_ID } from '../constants';

export default {
  name: 'ModelCreate',
  components: {
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlModal,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    ImportArtifactZone: () => import('./import_artifact_zone.vue'),
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['projectPath', 'maxAllowedFileSize', 'markdownPreviewPath'],
  props: {
    initialValue: {
      type: String,
      required: false,
      default: '',
    },
    disableAttachments: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      name: null,
      version: null,
      description: this.initialValue || '',
      versionDescription: null,
      errorMessage: null,
      selectedFile: emptyArtifactFile,
      modelData: null,
      versionData: null,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
    };
  },
  computed: {
    showImportArtifactZone() {
      return this.version && this.name;
    },
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    modelNameIsValid() {
      return this.name && noSpacesRegex.test(this.name);
    },
    isSemver() {
      return semverRegex.test(this.version);
    },
    isVersionValid() {
      return !this.version || this.isSemver;
    },
    submitButtonDisabled() {
      return !this.isVersionValid || !this.modelNameIsValid;
    },
    actionPrimary() {
      return {
        text: s__('MlModelRegistry|Create'),
        attributes: { variant: 'confirm', disabled: this.submitButtonDisabled },
      };
    },
    validVersionFeedback() {
      if (this.isSemver) {
        return this.$options.modal.versionValid;
      }
      return null;
    },
    modelNameDescription() {
      return !this.name || this.modelNameIsValid ? this.$options.modal.nameDescription : '';
    },
    versionDescriptionText() {
      return !this.version ? this.$options.modal.versionDescription : '';
    },
  },
  methods: {
    async createModel() {
      const { data } = await this.$apollo.mutate({
        mutation: createModelMutation,
        variables: {
          projectPath: this.projectPath,
          name: this.name,
          description: this.description,
        },
      });
      return data;
    },
    async createModelVersion(modelGid) {
      const { data } = await this.$apollo.mutate({
        mutation: createModelVersionMutation,
        variables: {
          projectPath: this.projectPath,
          modelId: modelGid,
          version: this.version,
          description: this.versionDescription,
        },
      });
      return data;
    },
    async create($event) {
      $event.preventDefault();

      this.errorMessage = '';
      try {
        // Attempt creating a model if needed
        if (!this.modelData) {
          this.modelData = await this.createModel();
        }
        const modelErrors = this.modelData?.mlModelCreate?.errors || [];
        if (modelErrors.length) {
          this.errorMessage = modelErrors.join(', ');
          this.modelData = null;
        } else if (this.version) {
          // Attempt creating a version if needed
          if (!this.versionData) {
            this.versionData = await this.createModelVersion(this.modelData.mlModelCreate.model.id);
          }
          const versionErrors = this.versionData?.mlModelVersionCreate?.errors || [];

          if (versionErrors.length) {
            this.errorMessage = versionErrors.join(', ');
            this.versionData = null;
          } else {
            // Attempt importing model artifacts
            const { importPath } = this.versionData.mlModelVersionCreate.modelVersion._links;
            await uploadModel({
              importPath,
              file: this.selectedFile.file,
              subfolder: this.selectedFile.subfolder,
              maxAllowedFileSize: this.maxAllowedFileSize,
              onUploadProgress: this.$refs.importArtifactZoneRef.onUploadProgress,
            });

            const { showPath } = this.versionData.mlModelVersionCreate.modelVersion._links;
            visitUrl(showPath);
          }
        } else {
          const { showPath } = this.modelData.mlModelCreate.model._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
        this.selectedFile = emptyArtifactFile;
      }
    },
    resetModal() {
      this.name = null;
      this.modelData = null;
      this.description = null;
      this.version = null;
      this.versionDescription = null;
      this.errorMessage = null;
      this.selectedFile = emptyArtifactFile;
      this.versionData = null;
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
    id: MODEL_CREATION_MODAL_ID,
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
    nameDescriptionLabel: s__('MlModelRegistry|Must be unique. May not contain spaces.'),
    nameDescription: s__('MlModelRegistry|Example: my-model'),
    nameInvalid: s__('MlModelRegistry|May not contain spaces.'),
    namePlaceholder: s__('MlModelRegistry|Enter a model name'),
    versionDescription: s__('MlModelRegistry|Example: 1.0.0'),
    versionPlaceholder: s__('MlModelRegistry|Enter a semantic version'),
    nameDescriptionPlaceholder: s__('MlModelRegistry|Enter a model description'),
    versionDescriptionTitle: s__('MlModelRegistry|Version description'),
    versionDescriptionLabel: s__(
      'MlModelRegistry|Must be a semantic version. Leave blank to skip version creation.',
    ),
    versionValid: s__('MlModelRegistry|Version is a valid semantic version.'),
    versionInvalid: s__('MlModelRegistry|Must be a semantic version. Example: 1.0.0'),
    versionDescriptionPlaceholder: s__('MlModelRegistry|Enter a version description'),
    buttonTitle: s__('MlModelRegistry|Create model'),
    title: s__('MlModelRegistry|Create model, version & import artifacts'),
    modelName: s__('MlModelRegistry|Model name'),
    modelDescription: __('Model description'),
    version: __('Version'),
    uploadLabel: __('Upload artifacts'),
    modelSuccessButVersionArtifactFailAlert: {
      id: 'ml-model-success-version-artifact-failed',
      message: s__(
        'MlModelRegistry|Model has been created but version or artifacts could not be uploaded. Try creating model version.',
      ),
      variant: 'warning',
    },
    optionalText: s__('MlModelRegistry|(Optional)'),
  },
};
</script>

<template>
  <div>
    <gl-button v-gl-modal="$options.modal.id">{{ $options.modal.buttonTitle }}</gl-button>
    <gl-modal
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="lg"
      @primary="create"
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
            v-model="name"
            data-testid="nameId"
            type="text"
            :placeholder="$options.modal.namePlaceholder"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.modal.modelDescription"
          data-testid="descriptionGroupId"
          label-for="descriptionId"
          optional
          :optional-text="$options.modal.optionalText"
          class="common-note-form gfm-form js-main-target-form gl-flex-grow-1 new-note"
        >
          <markdown-editor
            ref="markdownEditor"
            data-testid="descriptionId"
            :value="description"
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
        <gl-form-group
          :label="$options.modal.version"
          :label-description="$options.modal.versionDescriptionLabel"
          data-testid="versionGroupId"
          label-for="versionId"
          :state="isVersionValid"
          :invalid-feedback="$options.modal.versionInvalid"
          :valid-feedback="validVersionFeedback"
          :description="versionDescriptionText"
          optional
          :optional-text="$options.modal.optionalText"
        >
          <gl-form-input
            id="versionId"
            v-model="version"
            data-testid="versionId"
            type="text"
            :placeholder="$options.modal.versionPlaceholder"
            autocomplete="off"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.modal.versionDescriptionTitle"
          data-testid="versionDescriptionGroupId"
          label-for="versionDescriptionId"
          optional
          :optional-text="$options.modal.optionalText"
        >
          <gl-form-textarea
            id="versionDescriptionId"
            v-model="versionDescription"
            data-testid="versionDescriptionId"
            :placeholder="$options.modal.versionDescriptionPlaceholder"
          />
        </gl-form-group>
        <gl-form-group
          v-if="showImportArtifactZone"
          data-testid="importArtifactZoneLabel"
          :label="$options.modal.uploadLabel"
          label-for="versionImportArtifactZone"
        >
          <import-artifact-zone
            id="versionImportArtifactZone"
            ref="importArtifactZoneRef"
            v-model="selectedFile"
            class="gl-px-3 gl-py-0"
            :submit-on-select="false"
          />
        </gl-form-group>
      </gl-form>

      <gl-alert
        v-if="errorMessage"
        data-testid="modalCreateAlert"
        variant="danger"
        @dismiss="hideAlert"
        >{{ errorMessage }}
      </gl-alert>
    </gl-modal>
  </div>
</template>
