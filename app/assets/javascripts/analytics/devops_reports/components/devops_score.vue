<script>
import { GlBadge, GlTableLite, GlLink, GlEmptyState } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sprintf, s__ } from '~/locale';
import DevopsScoreCallout from './devops_score_callout.vue';

const defaultHeaderAttrs = {
  thClass: 'gl-bg-white!',
  thAttr: { 'data-testid': 'header' },
};

export default {
  components: {
    GlBadge,
    GlTableLite,
    GlSingleStat,
    GlLink,
    GlEmptyState,
    DevopsScoreCallout,
  },
  inject: {
    devopsScoreMetrics: {
      default: null,
    },
    noDataImagePath: {
      default: '',
    },
  },
  computed: {
    titleHelperText() {
      return sprintf(
        s__(
          'DevopsReport|DevOps score metrics are based on usage over the last 30 days. Last updated: %{timestamp}.',
        ),
        { timestamp: this.devopsScoreMetrics.createdAt },
      );
    },
    isEmpty() {
      return this.devopsScoreMetrics.averageScore === undefined;
    },
  },
  devopsReportDocsPath: helpPagePath('administration/analytics/dev_ops_reports'),
  tableHeaderFields: [
    {
      key: 'title',
      label: '',
      ...defaultHeaderAttrs,
    },
    {
      key: 'usage',
      label: s__('DevopsReport|Your usage'),
      ...defaultHeaderAttrs,
    },
    {
      key: 'leadInstance',
      label: s__('DevopsReport|Leader usage'),
      ...defaultHeaderAttrs,
    },
    {
      key: 'score',
      label: s__('DevopsReport|Score'),
      ...defaultHeaderAttrs,
    },
  ],
};
</script>
<template>
  <div data-testid="devops-score-container">
    <devops-score-callout />
    <gl-empty-state
      v-if="isEmpty"
      :title="__('Data is still calculating...')"
      :svg-path="noDataImagePath"
    >
      <template #description>
        <p class="gl-mb-0">{{ __('It may be several days before you see feature usage data.') }}</p>
        <gl-link :href="$options.devopsReportDocsPath">{{
          __('See example DevOps Score page in our documentation.')
        }}</gl-link>
      </template>
    </gl-empty-state>
    <div v-else data-testid="devops-score-app">
      <div class="gl-text-gray-400 gl-my-4" data-testid="devops-score-note-text">
        {{ titleHelperText }}
      </div>
      <gl-single-stat
        unit="%"
        size="sm"
        :title="s__('DevopsReport|Your score')"
        :should-animate="true"
        :value="devopsScoreMetrics.averageScore.value"
        :meta-icon="devopsScoreMetrics.averageScore.scoreLevel.icon"
        :meta-text="devopsScoreMetrics.averageScore.scoreLevel.label"
        :variant="devopsScoreMetrics.averageScore.scoreLevel.variant"
      />
      <gl-table-lite
        :fields="$options.tableHeaderFields"
        :items="devopsScoreMetrics.cards"
        thead-class="gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
        stacked="sm"
      >
        <template #cell(usage)="{ item }">
          <div data-testid="usageCol">
            <span>{{ item.usage }}</span>
            <gl-badge :variant="item.scoreLevel.variant" size="sm" class="gl-ml-1">{{
              item.scoreLevel.label
            }}</gl-badge>
          </div>
        </template>
      </gl-table-lite>
    </div>
  </div>
</template>
