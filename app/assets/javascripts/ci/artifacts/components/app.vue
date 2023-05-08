<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import getBuildArtifactsSizeQuery from '../graphql/queries/get_build_artifacts_size.query.graphql';
import { PAGE_TITLE, TOTAL_ARTIFACTS_SIZE, SIZE_UNKNOWN } from '../constants';
import JobArtifactsTable from './job_artifacts_table.vue';

export default {
  name: 'ArtifactsApp',
  components: {
    GlSkeletonLoader,
    JobArtifactsTable,
  },
  inject: ['projectPath'],
  apollo: {
    buildArtifactsSize: {
      query: getBuildArtifactsSizeQuery,
      variables() {
        return { projectPath: this.projectPath };
      },
      update({ project: { statistics } }) {
        return statistics?.buildArtifactsSize ?? null;
      },
    },
  },
  data() {
    return {
      buildArtifactsSize: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.buildArtifactsSize.loading;
    },
    humanReadableArtifactsSize() {
      return numberToHumanSize(this.buildArtifactsSize);
    },
  },
  i18n: {
    PAGE_TITLE,
    TOTAL_ARTIFACTS_SIZE,
    SIZE_UNKNOWN,
  },
};
</script>
<template>
  <div>
    <h1 class="page-title gl-font-size-h-display gl-mb-0" data-testid="artifacts-page-title">
      {{ $options.i18n.PAGE_TITLE }}
    </h1>
    <div class="gl-mb-6" data-testid="build-artifacts-size">
      <gl-skeleton-loader v-if="isLoading" :lines="1" />
      <template v-else>
        <strong>{{ $options.i18n.TOTAL_ARTIFACTS_SIZE }}</strong>
        <span v-if="buildArtifactsSize !== null">{{ humanReadableArtifactsSize }}</span>
        <span v-else>{{ $options.i18n.SIZE_UNKNOWN }}</span>
      </template>
    </div>
    <job-artifacts-table />
  </div>
</template>
