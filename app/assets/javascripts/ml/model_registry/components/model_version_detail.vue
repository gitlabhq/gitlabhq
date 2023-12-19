<script>
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PACKAGES_PACKAGE } from '~/graphql_shared/constants';
import * as i18n from '../translations';
import CandidateDetail from './candidate_detail.vue';

export default {
  name: 'ModelVersionDetail',
  components: {
    PackageFiles: () =>
      import('~/packages_and_registries/package_registry/components/details/package_files.vue'),
    CandidateDetail,
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
  i18n,
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg gl-mt-5">{{ $options.i18n.DESCRIPTION_LABEL }}</h3>

    <div v-if="modelVersion.description">
      {{ modelVersion.description }}
    </div>
    <div v-else class="gl-text-secondary">
      {{ $options.i18n.NO_DESCRIPTION_PROVIDED_LABEL }}
    </div>

    <template v-if="modelVersion.packageId">
      <package-files
        :package-id="packageId"
        :project-path="projectPath"
        :package-type="packageType"
      />
    </template>

    <div class="gl-mt-5">
      <span class="gl-font-weight-bold">{{ $options.i18n.MLFLOW_ID_LABEL }}:</span>
      {{ modelVersion.candidate.info.eid }}
    </div>

    <candidate-detail :candidate="modelVersion.candidate" :show-info-section="false" />
  </div>
</template>
