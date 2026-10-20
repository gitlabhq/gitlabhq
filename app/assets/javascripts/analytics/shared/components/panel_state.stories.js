import {
  PANEL_STATE_ERROR,
  PANEL_STATE_ERROR_NO_RETRY,
  PANEL_STATE_NO_ACCESS,
  PANEL_STATE_NO_DATA,
  PANEL_STATE_NOT_CONFIGURED,
  PANEL_STATE_UNAVAILABLE,
} from '../constants';
import PanelState from './panel_state.vue';

const variants = [
  PANEL_STATE_NO_DATA,
  PANEL_STATE_NO_ACCESS,
  PANEL_STATE_NOT_CONFIGURED,
  PANEL_STATE_UNAVAILABLE,
  PANEL_STATE_ERROR,
  PANEL_STATE_ERROR_NO_RETRY,
];

export default {
  component: PanelState,
  title: 'analytics/shared/components/panel_state',
  argTypes: {
    variant: {
      control: 'select',
      options: variants,
      description: 'Which state to show. Each one has its own default title and description.',
    },
    compact: {
      control: 'boolean',
      description: 'Left-aligned layout with a smaller heading, used for stat tiles.',
    },
    title: { control: 'text', description: "Replaces the variant's default title." },
    description: { control: 'text', description: "Replaces the variant's default description." },
  },
};

const Template = (args, { argTypes }) => ({
  components: { PanelState },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-flex gl-h-48 gl-rounded-lg gl-border gl-p-5">
      <panel-state v-bind="$props" />
    </div>`,
});

export const NoData = Template.bind({});
NoData.args = { variant: PANEL_STATE_NO_DATA };

export const NoAccess = Template.bind({});
NoAccess.args = { variant: PANEL_STATE_NO_ACCESS };

export const NotConfigured = Template.bind({});
NotConfigured.args = { variant: PANEL_STATE_NOT_CONFIGURED };

export const Unavailable = Template.bind({});
Unavailable.args = { variant: PANEL_STATE_UNAVAILABLE };

export const Error = Template.bind({});
Error.args = { variant: PANEL_STATE_ERROR };

export const ErrorNoRetry = Template.bind({});
ErrorNoRetry.args = { variant: PANEL_STATE_ERROR_NO_RETRY };

export const CompactNoData = Template.bind({});
CompactNoData.args = { variant: PANEL_STATE_NO_DATA, compact: true };

export const CompactError = Template.bind({});
CompactError.args = { variant: PANEL_STATE_ERROR, compact: true };

export const CustomCopy = Template.bind({});
CustomCopy.args = {
  variant: PANEL_STATE_NO_DATA,
  title: 'No merge requests yet',
  description: 'Merge requests merged in this period appear here.',
};
