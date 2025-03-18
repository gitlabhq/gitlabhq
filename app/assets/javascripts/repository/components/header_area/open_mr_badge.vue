<script>
import { GlBadge, GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import getOpenMrCountForBlobPath from '~/repository/queries/open_mr_count.query.graphql';
import getOpenMrsForBlobPath from '~/repository/queries/open_mrs.query.graphql';
import { nDaysBefore } from '~/lib/utils/datetime/date_calculation_utility';
import { toYmd } from '~/analytics/shared/utils';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MergeRequestListItem from './merge_request_list_item.vue';

const OPEN_MR_AGE_LIMIT_DAYS = 30;

export default {
  components: {
    GlBadge,
    GlPopover,
    GlSkeletonLoader,
    MergeRequestListItem,
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
      openMrs: [],
      isPopoverOpen: false,
    };
  },
  computed: {
    openMRsCountText() {
      return sprintf(s__('OpenMrBadge|%{count} open'), { count: this.openMrsCount });
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
      query: getOpenMrCountForBlobPath,
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
    openMrs: {
      query: getOpenMrsForBlobPath,
      variables() {
        return this.queryVariables;
      },
      skip() {
        return !this.isPopoverOpen;
      },
      update: (data) => data?.project?.mergeRequests?.nodes || [],
      error(error) {
        logError(
          `Failed to fetch merge requests. See exception details for more information.`,
          error,
        );
        Sentry.captureException(error);
      },
    },
  },
};
</script>

<template>
  <div id="open-mr-badge">
    <gl-badge v-if="showBadge" variant="success" icon="merge-request">
      {{ openMRsCountText }}
    </gl-badge>
    <gl-popover
      target="open-mr-badge"
      boundary="viewport"
      placement="bottomleft"
      @show.once="isPopoverOpen = true"
      @hide.once="isPopoverOpen = false"
    >
      <gl-skeleton-loader v-if="!openMrs.length || isLoading" :height="15">
        <rect width="250" height="15" rx="4" />
      </gl-skeleton-loader>
      <ul v-else class="flex-column gl-m-0 gl-flex gl-list-none gl-gap-4 gl-p-0">
        <li
          v-for="(mergeRequest, index) in openMrs"
          :key="mergeRequest.iid"
          class="gl-p-0"
          :class="{ 'gl-border-t gl-pt-4': index !== 0 }"
        >
          <merge-request-list-item :merge-request="mergeRequest" />
        </li>
      </ul>
    </gl-popover>
  </div>
</template>
