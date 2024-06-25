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
import { uploadModel } from '../services/upload_model';
import createModelVersionMutation from '../graphql/mutations/create_model_version.mutation.graphql';
import createModelMutation from '../graphql/mutations/create_model.mutation.graphql';
import { emptyArtifactFile, MODEL_CREATION_MODAL_ID } from '../constants';

export default {
  name: 'ModelCreate',
  components: {
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
  inject: ['projectPath', 'maxAllowedFileSize'],
  data() {
    return {
      name: null,
      version: null,
      description: null,
      versionDescription: null,
      errorMessage: null,
      selectedFile: emptyArtifactFile,
      modelData: null,
      versionData: null,
    };
  },
  computed: {
    showImportArtifactZone() {
      return this.version && this.name;
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
  },
  i18n: {},
  modal: {
    id: MODEL_CREATION_MODAL_ID,
    actionPrimary: {
      text: __('Create'),
      attributes: { variant: 'confirm' },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
    nameDescription: s__(
      'MlModelRegistry|Model name must not contain spaces or upper case letter.',
    ),
    namePlaceholder: s__('MlModelRegistry|For example my-model'),
    versionDescription: s__('MlModelRegistry|Leave empty to skip version creation.'),
    versionPlaceholder: s__('MlModelRegistry|For example 1.0.0. Must be a semantic version.'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter a model description'),
    versionDescriptionTitle: s__('MlModelRegistry|Version description'),
    versionDescriptionPlaceholder: s__(
      'MlModelRegistry|Enter a description for this version of the model.',
    ),
    buttonTitle: s__('MlModelRegistry|Create model'),
    title: s__('MlModelRegistry|Create model, version & import artifacts'),
    modelName: s__('MlModelRegistry|Model name'),
    modelDescription: __('Description'),
    version: __('Version'),
    uploadLabel: __('Upload artifacts'),
    modelSuccessButVersionArtifactFailAlert: {
      id: 'ml-model-success-version-artifact-failed',
      message: s__(
        'MlModelRegistry|Model has been created but version or artifacts could not be uploaded. Try creating model version.',
      ),
      variant: 'warning',
    },
  },
};
</script>

<template>
  <div>
    <gl-button v-gl-modal="$options.modal.id">{{ $options.modal.buttonTitle }}</gl-button>
    <gl-modal
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="sm"
      @primary="create"
      @secondary="resetModal"
    >
      <gl-form>
        <gl-form-group
          :label="$options.modal.modelName"
          label-for="nameId"
          :description="$options.modal.nameDescription"
        >
          <gl-form-input
            id="nameId"
            v-model="name"
            data-testid="nameId"
            type="text"
            :placeholder="$options.modal.namePlaceholder"
          />
        </gl-form-group>
        <gl-form-group :label="$options.modal.modelDescription" label-for="descriptionId">
          <gl-form-textarea
            id="descriptionId"
            v-model="description"
            data-testid="descriptionId"
            :placeholder="$options.modal.descriptionPlaceholder"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.modal.version"
          label-for="versionId"
          :description="$options.modal.versionDescription"
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
          label-for="versionDescriptionId"
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
        data-testid="modal-create-alert"
        variant="danger"
        @dismiss="hideAlert"
        >{{ errorMessage }}</gl-alert
      >
    </gl-modal>
  </div>
</template>
