<script>
import {
  GlProgressBar,
  GlLink,
  GlBadge,
  GlButton,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { MAX_MILESTONES_TO_DISPLAY } from '../constants';
import { sum } from 'lodash';

export default {
  name: 'ReleaseBlockMilestoneInfo',
  components: {
    GlProgressBar,
    GlLink,
    GlBadge,
    GlButton,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    milestones: {
      type: Array,
      required: true,
    },
    openIssuesPath: {
      type: String,
      required: false,
      default: '',
    },
    closedIssuesPath: {
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
      const percent = Math.round((this.closedIssuesCount / this.totalIssuesCount) * 100);
      return Number.isNaN(percent) ? 0 : percent;
    },
    allIssueStats() {
      return this.milestones.map(m => m.issueStats || {});
    },
    totalIssuesCount() {
      return sum(this.allIssueStats.map(stats => stats.total || 0));
    },
    closedIssuesCount() {
      return sum(this.allIssueStats.map(stats => stats.closed || 0));
    },
    openIssuesCount() {
      return this.totalIssuesCount - this.closedIssuesCount;
    },
    milestoneLabelText() {
      return n__('Milestone', 'Milestones', this.milestones.length);
    },
    issueCountsText() {
      return sprintf(__('Open: %{open} • Closed: %{closed}'), {
        open: this.openIssuesCount,
        closed: this.closedIssuesCount,
      });
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
  <div class="release-block-milestone-info d-flex align-items-start flex-wrap">
    <div
      v-gl-tooltip
      class="milestone-progress-bar-container js-milestone-progress-bar-container d-flex flex-column align-items-start flex-shrink-1 mr-4 mb-3"
      :title="__('Closed issues')"
    >
      <span class="mb-2">{{ percentCompleteText }}</span>
      <span class="w-100">
        <gl-progress-bar :value="closedIssuesCount" :max="totalIssuesCount" variant="success" />
      </span>
    </div>
    <div class="d-flex flex-column align-items-start mr-4 mb-3 js-milestone-list-container">
      <span class="mb-1">{{ milestoneLabelText }}</span>
      <div class="d-flex flex-wrap align-items-end">
        <template v-for="(milestone, index) in milestonesToDisplay">
          <gl-link
            :key="milestone.id"
            v-gl-tooltip
            :title="milestone.description"
            :href="milestone.webUrl"
            class="append-right-4"
          >
            {{ milestone.title }}
          </gl-link>
          <template v-if="shouldRenderBullet(index)">
            <span :key="'bullet-' + milestone.id" class="append-right-4">&bull;</span>
          </template>
          <template v-if="shouldRenderShowMoreLink(index)">
            <gl-button :key="'more-button-' + milestone.id" variant="link" @click="toggleShowAll">
              {{ moreText }}
            </gl-button>
          </template>
        </template>
      </div>
    </div>
    <div class="d-flex flex-column align-items-start flex-shrink-0 mr-4 mb-3 js-issues-container">
      <span class="mb-1">
        {{ __('Issues') }}
        <gl-badge pill variant="light" class="font-weight-bold">{{ totalIssuesCount }}</gl-badge>
      </span>
      <div class="d-flex">
        <gl-link v-if="openIssuesPath" ref="openIssuesLink" :href="openIssuesPath">
          <gl-sprintf :message="__('Open: %{openIssuesCount}')">
            <template #openIssuesCount>{{ openIssuesCount }}</template>
          </gl-sprintf>
        </gl-link>
        <span v-else ref="openIssuesText">
          {{ sprintf(__('Open: %{openIssuesCount}'), { openIssuesCount }) }}
        </span>

        <span class="mx-1">&bull;</span>

        <gl-link v-if="closedIssuesPath" ref="closedIssuesLink" :href="closedIssuesPath">
          <gl-sprintf :message="__('Closed: %{closedIssuesCount}')">
            <template #closedIssuesCount>{{ closedIssuesCount }}</template>
          </gl-sprintf>
        </gl-link>
        <span v-else ref="closedIssuesText">
          {{ sprintf(__('Closed: %{closedIssuesCount}'), { closedIssuesCount }) }}
        </span>
      </div>
    </div>
  </div>
</template>
