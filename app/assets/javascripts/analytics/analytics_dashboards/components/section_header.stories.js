import ExtendedDashboardPanel from '~/vue_shared/components/customizable_dashboard/extended_dashboard_panel.vue';
import SectionHeader from './section_header.vue';

export default {
  component: SectionHeader,
  title: 'analytics/analytics_dashboards/components/section_header',
  argTypes: {
    title: { control: 'text' },
    description: { control: 'text' },
    tooltip: {
      control: 'object',
      description: 'Optional popover. Needs a `description`; `title` is optional.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { SectionHeader },
  props: Object.keys(argTypes),
  template: `
    <section-header :title="title" :description="description" :tooltip="tooltip" />`,
});

// A section labels the panels beneath it, so show it against real panel chrome.
const AbovePanels = (args, { argTypes }) => ({
  components: { SectionHeader, ExtendedDashboardPanel },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-flex gl-flex-col gl-gap-4">
      <section-header :title="title" :description="description" :tooltip="tooltip" />
      <div class="gl-flex gl-gap-4">
        <extended-dashboard-panel class="gl-grow" title="Light">
          <template #body><p class="gl-m-0 gl-text-subtle">1&ndash;4 sessions</p></template>
        </extended-dashboard-panel>
        <extended-dashboard-panel class="gl-grow" title="Regular">
          <template #body><p class="gl-m-0 gl-text-subtle">5&ndash;24 sessions</p></template>
        </extended-dashboard-panel>
        <extended-dashboard-panel class="gl-grow" title="Heavy">
          <template #body><p class="gl-m-0 gl-text-subtle">25&ndash;99 sessions</p></template>
        </extended-dashboard-panel>
      </div>
    </div>`,
});

const title = 'Adoption tiers';
const description = 'How platform engagement is distributed across all users in the last 30 days';
const tooltip = {
  title,
  description:
    'All Duo users grouped by their total sessions across every activity in the period: Light 1-4, Regular 5-24, Heavy 25-99, Power 100+.',
};

export const Default = Template.bind({});
Default.args = { title, description, tooltip: {} };

export const TitleOnly = Template.bind({});
TitleOnly.args = { title, description: '', tooltip: {} };

export const WithTooltip = Template.bind({});
WithTooltip.args = { title, description, tooltip };

export const LongDescription = Template.bind({});
LongDescription.args = {
  title,
  description:
    'Every tier below is scoped to the selected group or project and the chosen date range. Values are aggregated nightly, so the most recent day may be incomplete until the next run finishes.',
  tooltip: {},
};

export const LabellingPanels = AbovePanels.bind({});
LabellingPanels.args = { title, description, tooltip };
