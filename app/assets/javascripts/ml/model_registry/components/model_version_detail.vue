<script>
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PACKAGES_PACKAGE } from '~/graphql_shared/constants';

export default {
  name: 'ModelVersionDetail',
  components: {
    PackageFiles: () =>
      import('~/packages_and_registries/package_registry/components/details/package_files.vue'),
  },
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    packageId() {
      return convertToGraphQLId(TYPENAME_PACKAGES_PACKAGE, this.modelVersion.packageId);
    },
    projectPath() {
      return this.modelVersion.projectPath;
    },
    packageType() {
      return 'ml_model';
    },
  },
};
</script>

<template>
  <div>
    <p>
      {{ modelVersion.description }}
    </p>
    <template v-if="modelVersion.packageId">
      <package-files
        :package-id="packageId"
        :project-path="projectPath"
        :package-type="packageType"
      />
    </template>
  </div>
</template>
