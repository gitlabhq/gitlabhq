<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlSkeletonLoader,
  GlTooltipDirective,
} from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
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
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlSkeletonLoader,
    MergeRequestListItem,
  },
  directives: { GlTooltip: GlTooltipDirective },
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
      isDropdownOpen: false,
    };
  },
  computed: {
    badgeTitle() {
      return s__(
        'OpenMrBadge|Open merge requests created in the past 30 days that target this branch and modify this file.',
      );
    },
    openMRsCountText() {
      return sprintf(s__('OpenMrBadge|%{count} Open'), { count: this.openMrsCount });
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
        return !this.isDropdownOpen;
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
  methods: {
    handleMergeRequestClick(webUrl) {
      visitUrl(webUrl);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="showBadge"
    :aria-label="openMRsCountText"
    :fluid-width="true"
    :loading="isLoading"
    placement="bottom-end"
    @shown="isDropdownOpen = true"
    @hidden="isDropdownOpen = false"
  >
    <template #toggle>
      <button class="gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0 gl-leading-0">
        <gl-badge
          v-gl-tooltip
          data-testid="open-mr-badge"
          variant="success"
          icon="merge-request"
          class="gl-h-full"
          :title="badgeTitle"
          :aria-label="badgeTitle"
        >
          {{ openMRsCountText }}
        </gl-badge>
      </button>
    </template>

    <template #header>
      <div class="gl-border-b-1 gl-border-gray-100 gl-p-4 gl-font-bold gl-border-b-solid">
        {{ s__('OpenMrBadge|Open merge requests') }}
        <gl-badge>{{ openMrsCount }}</gl-badge>
      </div>
    </template>

    <div v-if="!openMrs.length || isLoading" class="gl-w-34 gl-px-5 gl-py-3 md:gl-w-48">
      <gl-skeleton-loader :height="15">
        <rect width="250" height="15" rx="4" />
      </gl-skeleton-loader>
    </div>
    <ul v-else class="gl-m-0 gl-w-34 gl-p-0 md:gl-w-48">
      <gl-disclosure-dropdown-item
        v-for="mergeRequest in openMrs"
        :key="mergeRequest.iid"
        @action="handleMergeRequestClick(mergeRequest.webUrl)"
      >
        <template #list-item>
          <merge-request-list-item :merge-request="mergeRequest" />
        </template>
      </gl-disclosure-dropdown-item>
    </ul>
  </gl-disclosure-dropdown>
</template>
