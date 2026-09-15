import DashboardLayout from 'storybook_helpers/dashboards/dashboard_layout.vue';
import HeatMapChart from './heat_map_chart.vue';

export default {
  component: HeatMapChart,
  title: 'analytics/analytics_dashboards/components/visualizations/heat_map_chart',
};

const Template = (args, { argTypes }) => ({
  components: { HeatMapChart },
  props: Object.keys(argTypes),
  template: `
  <div>
    <heat-map-chart :data="data" :options="options" />
  </div>`,
});

// A real consumer would run the unit through n__() to pluralise it.
const WithUnitTooltip = (args, { argTypes }) => ({
  components: { HeatMapChart },
  props: Object.keys(argTypes),
  template: `
  <div>
    <heat-map-chart :data="data" :options="options">
      <template #tooltip-content="{ value }">
        {{ value.toLocaleString() }} sessions
      </template>
    </heat-map-chart>
  </div>`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { HeatMapChart, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <heat-map-chart :data="data" :options="options" />
      </dashboard-layout>`,
});

const cells = (rows) =>
  Object.entries(rows).flatMap(([row, columns]) =>
    Object.entries(columns).map(([column, value]) => ({ column, row, value })),
  );

// Tier bands are illustrative; the real cut-offs are still unsettled.
const sessionsByTier = cells({
  'Power (100+)': {
    Chat: 17024,
    'Software Development': 939,
    'Fix Pipeline': 355,
    Developer: 360,
    'Code Review': 25,
  },
  'Heavy (25-99)': {
    Chat: 12008,
    'Software Development': 501,
    'Fix Pipeline': 202,
    Developer: 188,
    'Code Review': 15,
  },
  'Regular (5-24)': {
    Chat: 6231,
    'Software Development': 165,
    'Fix Pipeline': 75,
    Developer: 60,
    'Code Review': 7,
  },
  'Light (1-4)': {
    Chat: 1344,
    'Software Development': 28,
    'Fix Pipeline': 13,
    Developer: 10,
    'Code Review': 1,
  },
});

// Cell labels need a compact formatter to fit a narrow column.
const compact = {
  formatValue: (value) => (value >= 1000 ? `${Math.round(value / 100) / 10}K` : String(value)),
};

export const Default = Template.bind({});
Default.args = { data: sessionsByTier, options: compact };

// Cell and tooltip format independently: "17K" in the cell, "17,024 sessions"
// on hover.
export const UnitInTooltip = WithUnitTooltip.bind({});
UnitInTooltip.args = { data: sessionsByTier, options: compact };

// The neutral should appear here and nowhere else.
export const WithEmptyCells = Template.bind({});
WithEmptyCells.args = {
  data: cells({
    'Power (100+)': { Chat: 17024, 'Software Development': 939, 'Fix Pipeline': 0 },
    'Heavy (25-99)': { Chat: 12008, 'Software Development': 0, 'Fix Pipeline': 202 },
    'Light (1-4)': { Chat: 1344, 'Software Development': 28, 'Fix Pipeline': 0 },
  }),
  options: compact,
};

// The row gutter is derived from the longest label, rather than the stock 64px.
export const LongRowLabels = Template.bind({});
LongRowLabels.args = {
  data: cells({
    'example-group/a-very-long-project-name': { Chat: 17024, 'Code Review': 355 },
    'example-group/tools': { Chat: 1344, 'Code Review': 13 },
  }),
  options: {},
};

// The worst case a GLQL query can reach: every flow type down the side and a
// weekly bucket per column over a six month range. Rows sit on their minimum
// height and column labels on their minimum width, so this is where truncation
// has to stay readable.
const FLOW_TYPES = [
  'duo_chat',
  'software_development',
  'code_review/v1',
  'developer/v1',
  'fix_pipeline/v1',
  'troubleshoot',
  'risk_classification/v1',
  'sast_fp_detection/v1',
  'resolve_sast_vulnerability/v1',
  'convert_to_gl_ci/v1',
  'recommend_reviewers/v1',
  'secrets_fp_detection/v1',
  'resolve_dependency_bump/experimental',
  'business_context_security_guidelines/experimental',
  'security_review/v1',
  'workplan/v1',
  'readiness_score/v1',
];

const WEEK_LABELS = Array.from({ length: 26 }, (_, index) => {
  const start = new Date(Date.UTC(2026, 2, 2 + index * 7));
  const end = new Date(Date.UTC(2026, 2, 8 + index * 7));
  const format = (date) =>
    date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' });

  return `${format(start)} - ${format(end)}`;
});

export const CrowdedGrid = Template.bind({});
CrowdedGrid.args = {
  data: FLOW_TYPES.flatMap((row, rowIndex) =>
    WEEK_LABELS.map((column, columnIndex) => ({
      column,
      row,
      value: Math.round(2 ** (FLOW_TYPES.length - rowIndex) * (1 + (columnIndex % 5))),
    })),
  ),
  options: compact,
};

// An auto-height ancestor chain would collapse the canvas here.
export const InDashboardPanel = WithDashboard.bind({});
InDashboardPanel.args = {
  data: sessionsByTier,
  options: compact,
  panelsConfig: [
    {
      id: '1',
      title: 'Sessions by tier and capability',
      gridAttributes: { yPos: 0, xPos: 0, width: 12, height: 4 },
    },
  ],
};
