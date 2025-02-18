<script>
import {
  GlIcon,
  GlPopover,
  GlSkeletonLoader,
  GlProgressBar,
  GlTooltipDirective,
  GlBadge,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { humanTimeframe, localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import {
  TYPE_MILESTONE,
  STATUS_UPCOMING,
  STATUS_ACTIVE,
  STATUS_EXPIRED,
  STATUS_CLOSED,
  issuableStatusText,
} from '~/issues/constants';

import query from '~/issuable/popover/queries/milestone.query.graphql';

export default {
  TYPE_MILESTONE,
  components: {
    GlIcon,
    GlBadge,
    GlPopover,
    GlProgressBar,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    target: {
      type: HTMLAnchorElement,
      required: true,
    },
    milestoneId: {
      type: String,
      required: true,
    },
    cachedTitle: {
      type: String,
      required: true,
    },
    placement: {
      type: String,
      required: false,
      default: 'top',
    },
  },
  data() {
    return {
      milestone: {},
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.milestone.loading;
    },
    title() {
      return this.milestone?.title || this.cachedTitle.split('%').slice(-1).pop();
    },
    milestoneParentIcon() {
      return this.milestone?.groupMilestone ? 'group' : 'project';
    },
    milestoneParentFullPath() {
      return this.milestone?.groupMilestone
        ? this.milestone?.group?.fullPath
        : this.milestone?.project?.fullPath;
    },
    status() {
      const { expired, upcoming, state } = this.milestone;
      if (state === STATUS_CLOSED) {
        return {
          variant: 'danger',
          text: issuableStatusText[STATUS_CLOSED],
        };
      }
      if (expired) {
        return {
          variant: 'warning',
          text: issuableStatusText[STATUS_EXPIRED],
        };
      }
      if (upcoming) {
        return {
          variant: 'muted',
          text: issuableStatusText[STATUS_UPCOMING],
        };
      }
      return {
        variant: 'success',
        text: issuableStatusText[STATUS_ACTIVE],
      };
    },
    milestoneStats() {
      return this.milestone?.stats || {};
    },
    progress() {
      const { closedIssuesCount = 0, totalIssuesCount = 0 } = this.milestoneStats;
      if (totalIssuesCount !== 0) {
        return Math.floor((closedIssuesCount / totalIssuesCount) * 100);
      }
      return 0;
    },
    showDetails() {
      return Object.keys(this.milestone).length > 0;
    },
    showTimeframe() {
      return !this.loading && Boolean(this.milestoneTimeframe);
    },
    showProgress() {
      return this.milestoneStats.totalIssuesCount !== 0;
    },
    percentageComplete() {
      return sprintf(__('%{percentage}%% complete'), { percentage: this.progress });
    },
    milestoneTimeframe() {
      const { startDate, dueDate } = this.milestone;
      const today = new Date();
      let timeframe = '';
      if (startDate && dueDate) {
        timeframe = humanTimeframe(newDate(startDate), newDate(dueDate));
      } else if (startDate && !dueDate) {
        const parsedStartDate = newDate(startDate);
        const startDateInWords = localeDateFormat.asDate.format(parsedStartDate);
        if (parsedStartDate.getTime() > today.getTime()) {
          timeframe = sprintf(__('Starts %{startDate}'), { startDate: startDateInWords });
        } else {
          timeframe = sprintf(__('Started %{startDate}'), { startDate: startDateInWords });
        }
      } else if (!startDate && dueDate) {
        const parsedDueDate = newDate(dueDate);
        const dueDateInWords = localeDateFormat.asDate.format(parsedDueDate);
        if (parsedDueDate.getTime() > today.getTime()) {
          timeframe = sprintf(__('Ends %{dueDate}'), { dueDate: dueDateInWords });
        } else {
          timeframe = sprintf(__('Ended %{dueDate}'), { dueDate: dueDateInWords });
        }
      }
      return timeframe;
    },
  },
  apollo: {
    milestone: {
      query,
      variables() {
        return {
          id: convertToGraphQLId(`Milestone`, this.milestoneId),
        };
      },
      update: (data) => data.milestone,
    },
  },
};
</script>

<template>
  <gl-popover
    :target="target"
    boundary="viewport"
    :placement="placement"
    :css-classes="['gl-min-w-fit']"
    show
  >
    <div class="gl-flex gl-items-center gl-gap-2">
      <gl-badge v-if="!loading && showDetails" :variant="status.variant">{{
        status.text
      }}</gl-badge>
      <span class="gl-flex gl-text-subtle" data-testid="milestone-label">
        <gl-icon name="milestone" class="gl-mr-1" variant="subtle" /> {{ __('Milestone') }}
      </span>
      <span v-if="showTimeframe" class="gl-text-subtle" data-testid="milestone-timeframe"
        >&middot; {{ milestoneTimeframe }}</span
      >
    </div>
    <gl-skeleton-loader v-if="loading" :height="15">
      <rect width="250" height="15" rx="4" />
    </gl-skeleton-loader>
    <h5 class="gl-my-3 gl-max-w-30">{{ title }}</h5>
    <div
      v-if="!loading && showProgress"
      class="gl-mt-2 gl-flex gl-items-center gl-gap-2"
      data-testid="milestone-progress"
    >
      <gl-progress-bar :value="progress" variant="primary" class="gl-h-3 gl-grow" />
      <span>{{ percentageComplete }}</span>
    </div>
    <div
      v-if="showDetails"
      class="gl-mt-2 gl-flex gl-items-center gl-gap-2"
      data-testid="milestone-path"
    >
      <gl-icon :name="milestoneParentIcon" class="gl-mr-1" />
      <span class="gl-text-subtle">{{ milestoneParentFullPath }}</span>
    </div>
  </gl-popover>
</template>
