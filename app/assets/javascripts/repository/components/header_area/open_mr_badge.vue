<script>
import { GlBadge } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import getOpenMrCountsForBlobPath from '~/repository/queries/open_mr_counts.query.graphql';
import { nDaysBefore } from '~/lib/utils/datetime/date_calculation_utility';
import { toYmd } from '~/analytics/shared/utils';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const OPEN_MR_AGE_LIMIT_DAYS = 30;

export default {
  components: {
    GlBadge,
  },
  inject: ['currentRef'],
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    blobPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      openMrsCount: null,
    };
  },
  computed: {
    openMRsCountText() {
      return sprintf(__('%{count} open'), { count: this.openMrsCount });
    },
    createdAfter() {
      const lookbackDate = nDaysBefore(new Date(), OPEN_MR_AGE_LIMIT_DAYS - 1, { utc: true });
      return toYmd(lookbackDate);
    },
    isLoading() {
      return this.$apollo.queries.loading;
    },
    showBadge() {
      return !this.isLoading && this.openMrsCount > 0;
    },
    queryVariables() {
      return {
        projectPath: this.projectPath,
        targetBranch: [this.currentRef],
        blobPath: this.blobPath,
        createdAfter: this.createdAfter,
      };
    },
  },
  apollo: {
    openMrsCount: {
      query: getOpenMrCountsForBlobPath,
      variables() {
        return this.queryVariables;
      },
      update({ project: { mergeRequests: { count } = {} } = {} } = {}) {
        return count;
      },
      error(error) {
        logError(
          `Failed to fetch merge request count. See exception details for more information.`,
          error,
        );
        Sentry.captureException(error);
      },
    },
  },
};
</script>

<template>
  <gl-badge v-if="showBadge" variant="success" icon="merge-request">
    {{ openMRsCountText }}
  </gl-badge>
</template>
