<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { semverRegex, noSpacesRegex } from '~/lib/utils/regexp';
import createModelVersionMutation from '../graphql/mutations/create_model_version.mutation.graphql';
import createModelMutation from '../graphql/mutations/create_model.mutation.graphql';

export default {
  name: 'ModelCreate',
  components: {
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    ImportArtifactZone: () => import('./import_artifact_zone.vue'),
  },
  inject: ['projectPath', 'maxAllowedFileSize', 'markdownPreviewPath'],
  props: {
    disableAttachments: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      name: null,
      version: null,
      description: '',
      versionDescription: '',
      errorMessage: null,
      modelData: null,
      versionData: null,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
      importErrorsText: null,
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
    validVersionFeedback() {
      if (this.isSemver) {
        return this.$options.i18n.versionValid;
      }
      return null;
    },
    modelNameDescription() {
      return !this.name || this.modelNameIsValid ? this.$options.i18n.nameDescription : '';
    },
    versionDescriptionText() {
      return !this.version ? this.$options.i18n.versionDescription : '';
    },
    importErrorsAlert() {
      return {
        id: 'import-artifact-alert',
        variant: this.importErrorsText ? 'danger' : 'info',
        message: this.importErrorsText
          ? `${this.$options.i18n.someFailed} ${this.importErrorsText}`
          : this.$options.i18n.allSucceeded,
      };
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
    async create() {
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
            const { showPath, importPath } =
              this.versionData.mlModelVersionCreate.modelVersion._links;
            await this.$refs.importArtifactZoneRef.uploadArtifact(importPath);
            visitUrlWithAlerts(showPath, [this.importErrorsAlert]);
          }
        } else {
          const { showPath } = this.modelData.mlModelCreate.model._links;
          visitUrlWithAlerts(showPath, [this.importErrorsAlert]);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
      }
    },
    resetForm() {
      this.name = null;
      this.version = null;
      this.description = '';
      this.versionDescription = '';
      this.errorMessage = null;
      this.modelData = null;
      this.versionData = null;
      this.importErrorsText = null;
    },
    hideAlert() {
      this.errorMessage = null;
    },
    setDescription(newText) {
      if (!this.isSubmitting) {
        this.description = newText;
      }
    },
    setVersionDescription(newVersionText) {
      if (!this.isSubmitting) {
        this.versionDescription = newVersionText;
      }
    },
    onImportError(error) {
      this.importErrorsText = error;
    },
  },
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model description'),
    id: 'model-description',
    name: 'model-description',
  },
  i18n: {
    allSucceeded: s__('MlModelRegistry|Artifacts uploaded successfully.'),
    someFailed: s__('MlModelRegistry|Artifact uploads completed with errors.'),
    actionPrimaryText: s__('MlModelRegistry|Create'),
    actionSecondaryText: __('Cancel'),
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
    <h2>{{ $options.i18n.title }}</h2>
    <gl-form>
      <gl-form-group
        :label="$options.i18n.modelName"
        :label-description="$options.i18n.nameDescriptionLabel"
        label-for="nameId"
        data-testid="nameGroupId"
        :state="modelNameIsValid"
        :invalid-feedback="$options.i18n.nameInvalid"
        :description="modelNameDescription"
      >
        <gl-form-input
          id="nameId"
          v-model="name"
          data-testid="nameId"
          type="text"
          :placeholder="$options.i18n.namePlaceholder"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.modelDescription"
        data-testid="descriptionGroupId"
        label-for="descriptionId"
        optional
        :optional-text="$options.i18n.optionalText"
        class="common-note-form gfm-form js-main-target-form new-note gl-grow"
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
          :placeholder="$options.i18n.nameDescriptionPlaceholder"
          :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
          @input="setDescription"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.version"
        :label-description="$options.i18n.versionDescriptionLabel"
        data-testid="versionGroupId"
        label-for="versionId"
        :state="isVersionValid"
        :invalid-feedback="$options.i18n.versionInvalid"
        :valid-feedback="validVersionFeedback"
        :description="versionDescriptionText"
        optional
        :optional-text="$options.i18n.optionalText"
      >
        <gl-form-input
          id="versionId"
          v-model="version"
          data-testid="versionId"
          type="text"
          :placeholder="$options.i18n.versionPlaceholder"
          autocomplete="off"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.versionDescriptionTitle"
        data-testid="versionDescriptionGroupId"
        label-for="versionDescriptionId"
        optional
        :optional-text="$options.i18n.optionalText"
        class="common-note-form gfm-form js-main-target-form new-note gl-grow"
      >
        <markdown-editor
          ref="markdownEditor"
          data-testid="versionDescriptionId"
          :value="versionDescription"
          enable-autocomplete
          :autocomplete-data-sources="autocompleteDataSources"
          :enable-content-editor="true"
          :form-field-props="$options.descriptionFormFieldProps"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocPath"
          :disable-attachments="disableAttachments"
          :placeholder="$options.i18n.versionDescriptionPlaceholder"
          :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
          @input="setVersionDescription"
        />
      </gl-form-group>
      <gl-form-group
        v-if="showImportArtifactZone"
        data-testid="importArtifactZoneLabel"
        :label="$options.i18n.uploadLabel"
        label-for="versionImportArtifactZone"
      >
        <import-artifact-zone
          id="versionImportArtifactZone"
          ref="importArtifactZoneRef"
          class="gl-px-3 gl-py-0"
          :submit-on-select="false"
          @error="onImportError"
        />
      </gl-form-group>
    </gl-form>

    <gl-alert v-if="errorMessage" data-testid="create-alert" variant="danger" @dismiss="hideAlert"
      >{{ errorMessage }}
    </gl-alert>

    <gl-button data-testid="secondary-button" variant="default" @click="resetForm"
      >{{ $options.i18n.actionSecondaryText }}
    </gl-button>

    <gl-button
      data-testid="primary-button"
      variant="confirm"
      :disabled="submitButtonDisabled"
      @click="create"
      >{{ $options.i18n.actionPrimaryText }}
    </gl-button>
  </div>
</template>
