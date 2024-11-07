<script>
import ImportArtifactZone from './import_artifact_zone.vue';

export default {
  name: 'ModelVersionArtifacts',
  components: {
    PackageFiles: () =>
      import('~/packages_and_registries/package_registry/components/details/package_files.vue'),
    ImportArtifactZone,
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
  },
};
</script>

<template>
  <div>
    <template v-if="modelVersion.packageId">
      <package-files
        :package-id="packageId"
        :can-delete="canWriteModelRegistry"
        :delete-all-files="true"
        :project-path="projectPath"
        :package-type="packageType"
      >
        <template v-if="showImportArtifactZone" #upload="{ refetch }">
          <h3 data-testid="uploadHeader" class="gl-text-lg">
            {{ __('Upload artifacts') }}
          </h3>
          <import-artifact-zone :path="importPath" @change="refetch" />
        </template>
      </package-files>
    </template>
  </div>
</template>
