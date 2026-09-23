import Stat from './stat.vue';

const METRIC_ONLY_FIELDS = [
  { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' },
];

// A stat aggregates to a single row, so the result carries one node.
const SINGLE_ROW = { nodes: [{ totalCount: 1234 }] };
const PREVIOUS_PERIOD_ROW = { nodes: [{ totalCount: 1000 }] };

export default {
  component: Stat,
  title: 'glql/components/presenters/stat',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    comparisonData: {
      control: false,
      description: 'Same query over the previous period, which is what derives the trend badge.',
    },
    fields: { control: false, description: 'Must be exactly one metric and no dimensions.' },
    loading: { control: 'boolean' },
    displayConfig: {
      control: 'object',
      description: 'Block `displayConfig`: title, unit, description, badge and icons.',
    },
    source: {
      control: 'text',
      description: 'Query data source. Supplies the derived description when none is authored.',
    },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { Stat },
  props: Object.keys(argTypes),
  template: `<stat
    :data="data"
    :comparison-data="comparisonData"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    :source="source"
    v-on="{ error }"
  />`,
});

// With no authored description, the source and metric supply one.
export const Default = Template.bind({});
Default.args = {
  data: SINGLE_ROW,
  fields: METRIC_ONLY_FIELDS,
  loading: false,
  displayConfig: {},
  source: 'MergeRequests',
};

// An authored description wins over the derived one.
export const AuthoredDescription = Template.bind({});
AuthoredDescription.args = {
  ...Default.args,
  displayConfig: { description: 'Merge requests merged in the last 30 days' },
};

export const WithTitleAndUnit = Template.bind({});
WithTitleAndUnit.args = {
  ...Default.args,
  displayConfig: { title: 'Merged this month', unit: 'MRs', titleIcon: 'merge-request' },
};

// A previous period derives the badge: more merge requests is a good move for a count,
// so the arrow points up and the badge is green.
export const WithTrend = Template.bind({});
WithTrend.args = {
  ...Default.args,
  comparisonData: PREVIOUS_PERIOD_ROW,
};

// A move from zero has no percentage, so the badge reads as new and stays neutral.
export const NewFromZero = Template.bind({});
NewFromZero.args = {
  ...Default.args,
  comparisonData: { nodes: [{ totalCount: 0 }] },
};

// An authored badge wins over the derived trend, so the two never contradict each other.
// The tooltip hangs off the badge, which only renders with `metaText`.
export const WithBadge = Template.bind({});
WithBadge.args = {
  ...Default.args,
  comparisonData: PREVIOUS_PERIOD_ROW,
  displayConfig: {
    metaText: '+12%',
    metaIcon: 'arrow-up',
    metaTooltip: 'Compared to the previous period',
    variant: 'success',
  },
};

// An aggregation over an empty set omits the node entirely, which reads as no value
// rather than as a zero.
export const NoValue = Template.bind({});
NoValue.args = {
  ...Default.args,
  data: { nodes: [] },
};

export const Loading = Template.bind({});
Loading.args = {
  ...Default.args,
  loading: true,
};

// An unknown badge variant is a block authoring error, so it surfaces before any result.
export const ValidationError = Template.bind({});
ValidationError.args = {
  ...Default.args,
  displayConfig: { variant: 'not-a-variant' },
};
