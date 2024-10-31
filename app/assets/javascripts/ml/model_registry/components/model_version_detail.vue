<script>
import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import { s__, __ } from '~/locale';

export default {
  name: 'ModelVersionDetail',
  components: {
    PackageFiles: () =>
      import('~/packages_and_registries/package_registry/components/details/package_files.vue'),
    ImportArtifactZone: () => import('./import_artifact_zone.vue'),
    IssuableDescription,
  },
  inject: ['projectPath', 'canWriteModelRegistry', 'importPath'],
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
    allowArtifactImport: {
      type: Boolean,
      required: false,
      default: false,
    },
    taskListUpdatePath: {
      type: String,
      required: false,
      default: '',
    },
    dataUpdateUrl: {
      type: String,
      required: false,
      default: null,
    },
    canEditRequirement: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableTaskList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    packageType() {
      return 'ml_model';
    },
    packageId() {
      return this.modelVersion.packageId;
    },
    showImportArtifactZone() {
      return this.canWriteModelRegistry && this.importPath && this.allowArtifactImport;
    },
    issuable() {
      return {
        titleHtml: this.modelVersion.name,
        descriptionHtml: this.modelVersion.descriptionHtml,
      };
    },
  },
  i18n: {
    EMPTY_VERSION_CARD_DESCRIPTION: s__(
      'MlModelRegistry|No description available. To add a description, click "Edit model version" above.',
    ),
    DESCRIPTION_LABEL: __('Description'),
    MLFLOW_ID_LABEL: s__('MlModelRegistry|MLflow run ID'),
  },
};
</script>

<template>
  <div>
    <h3 class="gl-mt-5 gl-text-lg">{{ $options.i18n.DESCRIPTION_LABEL }}</h3>

    <div class="issue-details issuable-details">
      <div
        v-if="modelVersion.descriptionHtml"
        class="detail-page-description js-detail-page-description content-block gl-pt-4"
      >
        <issuable-description
          data-testid="description"
          :issuable="issuable"
          :enable-task-list="enableTaskList"
          :can-edit="canEditRequirement"
          :data-update-url="dataUpdateUrl"
          :task-list-update-path="taskListUpdatePath"
        />
      </div>
      <div v-else class="gl-text-secondary" data-testid="emptyDescriptionState">
        {{ $options.i18n.EMPTY_VERSION_CARD_DESCRIPTION }}
      </div>
    </div>

    <template v-if="modelVersion.packageId">
      <package-files
        :package-id="packageId"
        :can-delete="canWriteModelRegistry"
        :delete-all-files="true"
        :project-path="projectPath"
        :package-type="packageType"
      >
        <template v-if="showImportArtifactZone" #upload="{ refetch }">
          <h3 data-testid="uploadHeader" class="gl-mt-5 gl-text-lg">
            {{ __('Upload artifacts') }}
          </h3>
          <import-artifact-zone :path="importPath" @change="refetch" />
        </template>
      </package-files>
    </template>
  </div>
</template>
