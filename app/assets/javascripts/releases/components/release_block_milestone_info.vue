<script>
import { GlProgressBar, GlLink, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { MAX_MILESTONES_TO_DISPLAY } from '../constants';
import IssuableStats from './issuable_stats.vue';

export default {
  name: 'ReleaseBlockMilestoneInfo',
  components: {
    GlProgressBar,
    GlLink,
    GlButton,
    IssuableStats,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    milestones: {
      type: Array,
      required: true,
    },
    openedIssuesPath: {
      type: String,
      required: false,
      default: '',
    },
    closedIssuesPath: {
      type: String,
      required: false,
      default: '',
    },
    openedMergeRequestsPath: {
      type: String,
      required: false,
      default: '',
    },
    mergedMergeRequestsPath: {
      type: String,
      required: false,
      default: '',
    },
    closedMergeRequestsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showAllMilestones: false,
    };
  },
  computed: {
    percentCompleteText() {
      return sprintf(__('%{percent}%{percentSymbol} complete'), {
        percent: this.percentComplete,
        percentSymbol: '%',
      });
    },
    percentComplete() {
      const percent = Math.round((this.issueCounts.closed / this.issueCounts.total) * 100);
      return Number.isNaN(percent) ? 0 : percent;
    },
    issueCounts() {
      return this.milestones
        .map((m) => m.issueStats || {})
        .reduce(
          (acc, current) => {
            acc.total += current.total || 0;
            acc.closed += current.closed || 0;

            return acc;
          },
          {
            total: 0,
            closed: 0,
          },
        );
    },
    showMergeRequestStats() {
      return this.milestones.some((m) => m.mrStats);
    },
    mergeRequestCounts() {
      return this.milestones
        .map((m) => m.mrStats || {})
        .reduce(
          (acc, current) => {
            acc.total += current.total || 0;
            acc.merged += current.merged || 0;
            acc.closed += current.closed || 0;

            return acc;
          },
          {
            total: 0,
            merged: 0,
            closed: 0,
          },
        );
    },
    milestoneLabelText() {
      return n__('Milestone', 'Milestones', this.milestones.length);
    },
    milestonesToDisplay() {
      return this.showAllMilestones
        ? this.milestones
        : this.milestones.slice(0, MAX_MILESTONES_TO_DISPLAY);
    },
    showMoreLink() {
      return this.milestones.length > MAX_MILESTONES_TO_DISPLAY;
    },
    moreText() {
      return this.showAllMilestones
        ? __('show fewer')
        : sprintf(__('show %{count} more'), {
            count: this.milestones.length - MAX_MILESTONES_TO_DISPLAY,
          });
    },
  },
  methods: {
    toggleShowAll() {
      this.showAllMilestones = !this.showAllMilestones;
    },
    shouldRenderBullet(milestoneIndex) {
      return Boolean(milestoneIndex !== this.milestonesToDisplay.length - 1 || this.showMoreLink);
    },
    shouldRenderShowMoreLink(milestoneIndex) {
      return Boolean(milestoneIndex === this.milestonesToDisplay.length - 1 && this.showMoreLink);
    },
  },
};
</script>
<template>
  <div class="release-block-milestone-info gl-display-flex gl-flex-wrap">
    <div
      v-gl-tooltip
      class="milestone-progress-bar-container js-milestone-progress-bar-container gl-display-flex gl-flex-direction-column gl-mr-6 gl-mb-5"
      :title="__('Closed issues')"
    >
      <span class="gl-mb-3">{{ percentCompleteText }}</span>
      <span class="gl-w-full">
        <gl-progress-bar :value="issueCounts.closed" :max="issueCounts.total" variant="success" />
      </span>
    </div>
    <div
      class="gl-display-flex gl-flex-direction-column gl-mr-6 gl-mb-5 js-milestone-list-container"
    >
      <span class="gl-mb-2">{{ milestoneLabelText }}</span>
      <div class="gl-display-flex gl-flex-wrap gl-align-items-flex-end">
        <template v-for="(milestone, index) in milestonesToDisplay">
          <gl-link
            :key="milestone.id"
            v-gl-tooltip
            :title="milestone.description"
            :href="milestone.webUrl"
            class="gl-mr-2"
          >
            {{ milestone.title }}
          </gl-link>
          <template v-if="shouldRenderBullet(index)">
            <span :key="'bullet-' + milestone.id" class="gl-mr-2">&bull;</span>
          </template>
          <template v-if="shouldRenderShowMoreLink(index)">
            <gl-button :key="'more-button-' + milestone.id" variant="link" @click="toggleShowAll">
              {{ moreText }}
            </gl-button>
          </template>
        </template>
      </div>
    </div>
    <issuable-stats
      :label="__('Issues')"
      :total="issueCounts.total"
      :closed="issueCounts.closed"
      :opened-path="openedIssuesPath"
      :closed-path="closedIssuesPath"
      data-testid="issue-stats"
    />
    <issuable-stats
      v-if="showMergeRequestStats"
      :label="__('Merge requests')"
      :total="mergeRequestCounts.total"
      :merged="mergeRequestCounts.merged"
      :closed="mergeRequestCounts.closed"
      :opened-path="openedMergeRequestsPath"
      :merged-path="mergedMergeRequestsPath"
      :closed-path="closedMergeRequestsPath"
      data-testid="merge-request-stats"
    />
  </div>
</template>
