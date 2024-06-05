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
import { emptyArtifactFile } from '../constants';

export default {
  name: 'ModelVersionCreate',
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
    modelGid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      version: null,
      description: null,
      modalVisible: false,
      errorMessage: null,
      selectedFile: emptyArtifactFile,
      versionData: null,
    };
  },
  methods: {
    async createModelVersion() {
      const { data } = await this.$apollo.mutate({
        mutation: createModelVersionMutation,
        variables: {
          projectPath: this.projectPath,
          modelId: this.modelGid,
          version: this.version,
          description: this.description,
        },
      });

      return data;
    },
    async create($event) {
      $event.preventDefault();

      this.errorMessage = '';
      try {
        if (!this.versionData) {
          this.versionData = await this.createModelVersion();
        }
        const errors = this.versionData?.mlModelVersionCreate?.errors || [];

        if (errors.length) {
          this.errorMessage = errors.join(', ');
          this.versionData = null;
        } else {
          const { importPath } = this.versionData.mlModelVersionCreate.modelVersion._links;

          await uploadModel({
            importPath,
            file: this.selectedFile.file,
            subfolder: this.selectedFile.subfolder,
          });
          const { showPath } = this.versionData.mlModelVersionCreate.modelVersion._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
        this.selectedFile = emptyArtifactFile;
        this.showModal();
      }
    },
    showModal() {
      this.modalVisible = true;
    },
    resetModal() {
      this.version = null;
      this.description = null;
      this.errorMessage = null;
      this.selectedFile = emptyArtifactFile;
      this.versionData = null;
    },
    cancelModal() {
      this.hideModal();
      this.resetModal();
    },
    hideModal() {
      this.modalVisible = false;
    },
    hideAlert() {
      this.errorMessage = null;
    },
  },
  i18n: {},
  modal: {
    id: 'ml-experiments-delete-modal',
    actionPrimary: {
      text: s__('MlModelRegistry|Create & import'),
      attributes: { variant: 'confirm' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
    versionDescription: s__('MlModelRegistry|Enter a semver version.'),
    versionPlaceholder: s__('MlModelRegistry|For example 1.0.0'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter some description'),
    buttonTitle: s__('MlModelRegistry|Create model version'),
    title: s__('MlModelRegistry|Create model version & import artifacts'),
  },
};
</script>

<template>
  <div>
    <gl-button @click="showModal">{{ $options.modal.buttonTitle }}</gl-button>
    <gl-modal
      v-model="modalVisible"
      modal-id="create-model-version-modal"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      size="sm"
      @primary="create"
      @cancel="cancelModal"
    >
      <gl-form>
        <gl-form-group
          label="Version:"
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
        <gl-form-group label="Description" label-for="descriptionId">
          <gl-form-textarea
            id="descriptionId"
            v-model="description"
            data-testid="descriptionId"
            :placeholder="$options.modal.descriptionPlaceholder"
          />
        </gl-form-group>
        <gl-form-group label="Import" label-for="versionImportArtifactZone">
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
