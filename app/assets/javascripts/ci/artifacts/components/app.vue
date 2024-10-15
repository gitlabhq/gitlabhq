<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import getBuildArtifactsSizeQuery from '../graphql/queries/get_build_artifacts_size.query.graphql';
import { PAGE_TITLE, TOTAL_ARTIFACTS_SIZE, SIZE_UNKNOWN } from '../constants';
import JobArtifactsTable from './job_artifacts_table.vue';

export default {
  name: 'ArtifactsApp',
  components: {
    GlSkeletonLoader,
    JobArtifactsTable,
    PageHeading,
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
    <page-heading :heading="$options.i18n.PAGE_TITLE">
      <template #description>
        <span data-testid="build-artifacts-size">
          <gl-skeleton-loader v-if="isLoading" :lines="1" />
          <template v-else>
            <strong>{{ $options.i18n.TOTAL_ARTIFACTS_SIZE }}</strong>
            <span v-if="buildArtifactsSize !== null">{{ humanReadableArtifactsSize }}</span>
            <span v-else>{{ $options.i18n.SIZE_UNKNOWN }}</span>
          </template>
        </span>
      </template>
    </page-heading>
    <job-artifacts-table />
  </div>
</template>
