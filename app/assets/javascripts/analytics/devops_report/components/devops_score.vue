<script>
import { GlBadge, GlTable } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { sprintf, s__ } from '~/locale';

const defaultHeaderAttrs = {
  thClass: 'gl-bg-white!',
  thAttr: { 'data-testid': 'header' },
};

export default {
  components: {
    GlBadge,
    GlTable,
    GlSingleStat,
  },
  inject: {
    devopsScoreMetrics: {
      default: null,
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
  },
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
  <div data-testid="devops-score-app">
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
    <gl-table
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
    </gl-table>
  </div>
</template>
