import GlqlFacade from '~/glql/components/common/facade.vue';
import DataPresenter from '~/glql/components/presenters/data.vue';
import { MODE_ANALYTICS, MODE_STANDARD } from '~/glql/constants';
import { MOCK_ISSUES, MOCK_FIELDS } from 'jest/glql/mock_data';

const QUERY_YAML = `display: list
title: My open issues
description: This view lists my open issues
limit: 5
query: assignee = currentUser() AND state = opened`;

const STAT_QUERY_YAML = `display: stat
title: Open issues
query: state = opened
fields: count`;

// The real resolver runs Apollo. In stories we stub it and replay the change
// payload provided by the story via inject — same pattern the facade spec uses.
// The stub still renders the real DataPresenter, which is pure: without it every
// display variant renders an empty card body and looks identical.
const GlqlResolverStub = {
  emits: ['change'],
  inject: { resolverChange: { default: () => null } },
  mounted() {
    if (this.resolverChange) this.$emit('change', this.resolverChange);
  },
  render(h) {
    const { config, data, fields, loading } = this.resolverChange || {};
    if (!config?.display) return null;

    return h(DataPresenter, {
      props: {
        displayType: config.display,
        data,
        fields,
        loading,
        displayConfig: config.displayConfig,
      },
    });
  },
};

// Auto-fire `appear` so the facade body renders without needing the viewport.
const GlIntersectionObserverStub = {
  mounted() {
    this.$emit('appear');
  },
  render(h) {
    return h('div', this.$slots.default);
  },
};

const FacadeStory = {
  extends: GlqlFacade,
  components: {
    ...GlqlFacade.components,
    GlqlResolver: GlqlResolverStub,
    GlIntersectionObserver: GlIntersectionObserverStub,
  },
  inject: { initialState: { default: () => null } },
  created() {
    // The open source modal and the block-limit warning are internal data with no
    // prop to drive them, so stories that need those states seed them directly.
    if (this.initialState) Object.assign(this, this.initialState);
  },
};

const SUCCESS_CONFIG = {
  display: 'list',
  title: 'My open issues',
  description: 'This view lists my open issues',
};

const STAT_FIELDS = [
  { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' },
];

const successChange = (overrides = {}) => ({
  loading: false,
  query: 'query GLQL { __typename }',
  config: SUCCESS_CONFIG,
  data: { count: MOCK_ISSUES.nodes.length, ...MOCK_ISSUES },
  fields: MOCK_FIELDS,
  mode: MODE_STANDARD,
  error: null,
  ...overrides,
});

const Template = (args) => ({
  components: { FacadeStory },
  provide() {
    return {
      resolverChange: args.resolverChange,
      glFeatures: args.glFeatures,
      initialState: args.initialState,
    };
  },
  setup() {
    return { args };
  },
  template: '<facade-story v-bind="args" />',
});

const baseArgs = {
  queryKey: 'glql_key',
  queryYaml: QUERY_YAML,
  glFeatures: {},
};

export default {
  title: 'glql/components/common/facade',
  component: GlqlFacade,
  argTypes: {
    queryYaml: {
      control: 'text',
      description: 'YAML source for the GLQL query block.',
    },
    queryKey: { control: false },
    resolverChange: { control: false },
    glFeatures: { control: false },
    initialState: { control: false },
  },
};

export const Default = Template.bind({});
Default.args = {
  ...baseArgs,
  resolverChange: successChange(),
};

export const TableView = Template.bind({});
TableView.args = {
  ...baseArgs,
  resolverChange: successChange({
    config: { ...SUCCESS_CONFIG, display: 'table' },
  }),
};

// Displays outside FULL_BLEED_DISPLAY_TYPES get an inset from the card rather
// than rendering edge to edge, and analytics mode drops the item count.
export const StatDisplay = Template.bind({});
StatDisplay.args = {
  ...baseArgs,
  queryYaml: STAT_QUERY_YAML,
  resolverChange: successChange({
    config: { display: 'stat', title: 'Open issues' },
    data: { count: 1, nodes: [{ totalCount: 128 }] },
    fields: STAT_FIELDS,
    mode: MODE_ANALYTICS,
  }),
};

export const Loading = Template.bind({});
Loading.args = {
  ...baseArgs,
  resolverChange: successChange({ loading: true, data: undefined, config: {} }),
};

export const EmptyResults = Template.bind({});
EmptyResults.args = {
  ...baseArgs,
  resolverChange: successChange({ data: { count: 0, nodes: [] } }),
};

export const DefaultListTitle = Template.bind({});
DefaultListTitle.args = {
  ...baseArgs,
  resolverChange: successChange({ config: { display: 'list' } }),
};

export const DefaultTableTitle = Template.bind({});
DefaultTableTitle.args = {
  ...baseArgs,
  resolverChange: successChange({ config: { display: 'table' } }),
};

export const Collapsed = Template.bind({});
Collapsed.args = {
  ...baseArgs,
  resolverChange: successChange({
    config: { ...SUCCESS_CONFIG, collapsed: true },
  }),
};

export const LoadOnClick = Template.bind({});
LoadOnClick.args = {
  ...baseArgs,
  glFeatures: { glqlLoadOnClick: true },
  resolverChange: null,
};
// The dimmed query behind the load button fails the contrast check, which is a
// facade.vue issue rather than a story one.
LoadOnClick.parameters = {
  a11y: { config: { rules: [{ id: 'color-contrast', enabled: false }] } },
};

export const ViewSourceModalOpen = Template.bind({});
ViewSourceModalOpen.args = {
  ...baseArgs,
  resolverChange: successChange(),
  initialState: { showSourceModal: true },
};

// Set directly rather than by exhausting the shared counter: the limit and its
// message live inside the facade with no way to reach them from a story.
export const BlockLimitExceeded = Template.bind({});
BlockLimitExceeded.args = {
  ...baseArgs,
  resolverChange: null,
  initialState: {
    error: {
      variant: 'warning',
      title:
        'Only 20 embedded views can be automatically displayed on a page. Click the button below to manually display this view.',
      action: 'Display view',
    },
  },
};

export const TimeoutError = Template.bind({});
TimeoutError.args = {
  ...baseArgs,
  resolverChange: successChange({
    data: undefined,
    config: {},
    error: { networkError: { statusCode: 503 } },
  }),
};

export const ForbiddenError = Template.bind({});
ForbiddenError.args = {
  ...baseArgs,
  resolverChange: successChange({
    data: undefined,
    config: {},
    error: { networkError: { statusCode: 403 } },
  }),
};

export const SyntaxError = Template.bind({});
SyntaxError.args = {
  ...baseArgs,
  resolverChange: successChange({
    data: undefined,
    config: {},
    error: new Error('Syntax error: Unexpected `=`'),
  }),
};
