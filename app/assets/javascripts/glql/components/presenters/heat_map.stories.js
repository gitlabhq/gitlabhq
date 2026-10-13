import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_TWO_DIMS,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import HeatMap from './heat_map.vue';

export default {
  component: HeatMap,
  title: 'glql/components/presenters/heat_map',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Must be exactly two dimensions and one metric.' },
    loading: { control: 'boolean' },
    displayConfig: {
      control: 'object',
      description: 'Block `displayConfig`, e.g. `description` or `maxColumns`.',
    },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { HeatMap },
  props: Object.keys(argTypes),
  template: `<heat-map
    :data="data"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    v-on="{ error }"
  />`,
});

// The first dimension becomes the columns and the second the rows.
export const Default = Template.bind({});
Default.args = {
  data: MOCK_AGGREGATED_DATA_TWO_DIMS,
  fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  loading: false,
  displayConfig: {},
};

export const WithDescription = Template.bind({});
WithDescription.args = {
  ...Default.args,
  displayConfig: { description: 'Code suggestions accepted per user and language' },
};

export const Loading = Template.bind({});
Loading.args = {
  ...Default.args,
  loading: true,
};

export const NoData = Template.bind({});
NoData.args = {
  ...Default.args,
  data: { nodes: [] },
};

const FLOW_TYPES = [
  'software_development',
  'chat',
  'agentic_chat/v1',
  'code_review/v1',
  'fix_pipeline/v1',
  'developer/v1',
  'duo_chat',
  'convert_to_gitlab_ci',
  'resolve_sast_vulnerability/v1',
  'sast_fp_detection/v1',
  'secrets_fp_detection/v1',
  'security_review/v1',
  'security_policy_review/v1',
  'risk_classification/v1',
  'recommend_reviewers/v1',
  'troubleshoot_job/v1',
  'workplan/v1',
  'readiness_score/v1',
  'trigger_flow/v1',
  'ai_catalog_item/v1',
  'analytics_insights/experimental',
  'ci_expert/experimental',
  'cloud_connector_probe',
  'code_conversion/experimental',
  'duo_planner/experimental',
  'flow_registry_sync',
  'orbit_sync/experimental',
  'ambient_agent/v1',
  'business_context_security_guidelines/experimental',
  'mid_year_review/experimental',
  'onboarding_assistant/experimental',
  'support_triage/experimental',
];

const FLOW_TYPE_FIELD = {
  key: 'flowType',
  label: 'Flow type',
  name: 'flowType',
  type: 'dimension',
};
const TIER_FIELD = {
  key: 'userTier',
  label: 'User tier',
  name: 'userTier',
  type: 'dimension',
  parameters: { thresholds: ['5', '25', '100'] },
};
const SESSIONS_FIELD = { key: 'totalCount', label: 'Sessions', name: 'totalCount', type: 'metric' };

const SESSIONS_BY_TIER = {
  // Sessions fall off across the list, so the five the cap keeps are obvious.
  nodes: FLOW_TYPES.flatMap((flowType, index) =>
    [3, 2, 1, 0].map((tier) => ({
      flowType,
      userTier: `tier_${tier}`,
      totalCount: (FLOW_TYPES.length - index) * (tier + 1),
    })),
  ),
};

// Capabilities across, at the cardinality a namespace using every flow type
// reaches, so the cap is what keeps the column labels readable.
export const WithMaxColumns = Template.bind({});
WithMaxColumns.args = {
  loading: false,
  displayConfig: { maxColumns: 5 },
  data: SESSIONS_BY_TIER,
  fields: [FLOW_TYPE_FIELD, TIER_FIELD, SESSIONS_FIELD],
};

// The DAP Impact panel's own shape: tiers across, capabilities down the side
// where the labels have room, capped to the busiest five.
export const WithMaxRows = Template.bind({});
WithMaxRows.args = {
  ...WithMaxColumns.args,
  displayConfig: { maxRows: 5 },
  fields: [TIER_FIELD, FLOW_TYPE_FIELD, SESSIONS_FIELD],
};

// A heat map needs both axes, so a single dimension is a block authoring error.
// The embedded view shows it as an alert; here it lands in the Actions panel.
export const ValidationError = Template.bind({});
ValidationError.args = {
  ...Default.args,
  data: MOCK_AGGREGATED_DATA_ONE_DIM,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
};
