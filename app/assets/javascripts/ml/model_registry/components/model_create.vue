<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlModal,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { uploadModel } from '../services/upload_model';
import createModelVersionMutation from '../graphql/mutations/create_model_version.mutation.graphql';
import createModelMutation from '../graphql/mutations/create_model.mutation.graphql';

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
  inject: ['projectPath'],
  props: {
    createModelVisible: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      name: null,
      version: null,
      description: null,
      versionDescription: null,
      errorMessage: null,
      selectedFile: null,
      modelData: null,
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
        // attempt creating a model
        if (!this.modelData) {
          this.modelData = await this.createModel();
        }
        const modelErrors = this.modelData?.mlModelCreate?.errors || [];
        if (modelErrors.length) {
          this.errorMessage = modelErrors.join(', ');
        } else if (this.version) {
          // model creation is successful, attempt creating a version
          const versionData = await this.createModelVersion(this.modelData.mlModelCreate.model.id);
          const versionErrors = versionData?.mlModelVersionCreate?.errors || [];

          if (versionErrors.length) {
            this.errorMessage = versionErrors.join(', ');
          } else {
            // attempt importing model artifacts
            const { importPath } = versionData.mlModelVersionCreate.modelVersion._links;
            await uploadModel({ importPath, file: this.selectedFile });
            const { showPath } = versionData.mlModelVersionCreate.modelVersion._links;
            visitUrl(showPath);
          }
        } else {
          const { showPath } = this.modelData.mlModelCreate.model._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = s__(
          'MlModelRegistry|Error creating model, version and uploading artifacts. Please try again.',
        );
      }
    },
    showCreateModal() {
      this.$emit('show-create-model');
    },
    cancelModal() {
      this.$emit('hide-create-model');
    },
    hideAlert() {
      this.errorMessage = null;
    },
  },
  i18n: {},
  modal: {
    id: 'ml-experiments-delete-modal',
    actionPrimary: {
      text: __('Create'),
      attributes: { variant: 'confirm' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
    nameDescription: s__(
      'MlModelRegistry|Model name must not contain spaces or upper case letter.',
    ),
    namePlaceholder: s__('MlModelRegistry|For example my-model'),
    versionDescription: s__('MlModelRegistry|Leave empty to skip version creation.'),
    versionPlaceholder: s__('MlModelRegistry|For example 1.0.0'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter some model description'),
    versionDescriptionTitle: s__('MlModelRegistry|Version Description'),
    versionDescriptionPlaceholder: s__(
      'MlModelRegistry|Initial version name. Must be a semantic version.',
    ),
    buttonTitle: s__('MlModelRegistry|Create model'),
    title: s__('MlModelRegistry|Create model, version & import artifacts'),
    modelName: s__('MlModelRegistry|Model name'),
    modelDescription: __('Description'),
    version: __('Version'),
    import: __('Import'),
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
    <gl-button @click="showCreateModal">{{ $options.modal.buttonTitle }}</gl-button>
    <gl-modal
      modal-id="create-model-modal"
      :visible="createModelVisible"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      size="sm"
      @primary="create"
      @hide="cancelModal"
      @cancel="cancelModal"
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
          :label="$options.modal.Import"
          label-for="versionImportArtifactZone"
        >
          <import-artifact-zone
            id="versionImportArtifactZone"
            v-model="selectedFile"
            :submit-on-select="false"
          />
        </gl-form-group>
      </gl-form>

      <gl-alert v-if="errorMessage" variant="danger" @dismiss="hideAlert">{{
        errorMessage
      }}</gl-alert>
    </gl-modal>
  </div>
</template>
