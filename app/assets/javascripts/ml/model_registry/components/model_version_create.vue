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
      selectedFile: { file: null, subfolder: '' },
    };
  },
  methods: {
    async createModelVersion($event) {
      $event.preventDefault();

      this.errorMessage = '';
      try {
        const { data } = await this.$apollo.mutate({
          mutation: createModelVersionMutation,
          variables: {
            projectPath: this.projectPath,
            modelId: this.modelGid,
            version: this.version,
            description: this.description,
          },
        });
        const errors = data?.mlModelVersionCreate?.errors || [];

        if (errors.length) {
          this.errorMessage = errors.join(', ');
        } else {
          const { importPath } = data.mlModelVersionCreate.modelVersion._links;

          await uploadModel({
            importPath,
            file: this.selectedFile.file,
            subfolder: this.selectedFile.subfolder,
          });
          const versionShowPath = data.mlModelVersionCreate.modelVersion._links.showPath;
          visitUrl(versionShowPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = s__(
          'MlModelRegistry|Error creating model version and uploading artifacts. Please try again.',
        );
      }
    },
    showCreateModal() {
      this.modalVisible = true;
    },
    cancelModal() {
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
    versionDescription: s__('MlModelRegistry|Leave empty to auto increment.'),
    versionPlaceholder: s__('MlModelRegistry|For example 1.0.0'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter some description'),
    buttonTitle: s__('MlModelRegistry|Create model version'),
    title: s__('MlModelRegistry|Create model version & import artifacts'),
  },
};
</script>

<template>
  <div>
    <gl-button @click="showCreateModal">{{ $options.modal.buttonTitle }}</gl-button>
    <gl-modal
      v-model="modalVisible"
      modal-id="create-model-version-modal"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      size="sm"
      @primary="createModelVersion"
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
