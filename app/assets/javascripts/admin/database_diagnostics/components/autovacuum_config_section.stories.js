import {
  autovacuumConfig,
  autovacuumConfigHealthy,
} from 'jest/admin/database_diagnostics/mock_data';
import AutovacuumConfigSection from './autovacuum_config_section.vue';

export default {
  title: 'admin/database_diagnostics/components/autovacuum_config_section',
  component: AutovacuumConfigSection,
  parameters: {
    docs: {
      description: {
        component:
          'Effective autovacuum settings, per-table overrides and scale factor risks. Both sections start collapsed, so use the Details toggles to reveal the tables.',
      },
    },
  },
  argTypes: {
    config: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AutovacuumConfigSection },
  template: '<autovacuum-config-section v-bind="$props" />',
});

// Per-setting findings render as status badges in the settings table rather
// than as alerts. One override has autovacuum disabled, which is the only
// adverse signal among overrides.
export const Default = Template.bind({});
Default.args = { config: autovacuumConfig };

export const Healthy = Template.bind({});
Healthy.args = { config: autovacuumConfigHealthy };

// Only the per-setting findings survive, because the two table-level ones
// describe overrides and risks this config no longer has.
export const NoTableOverrides = Template.bind({});
NoTableOverrides.args = {
  config: {
    ...autovacuumConfig,
    findings: autovacuumConfig.findings.filter((finding) => finding.setting_name),
    table_overrides: [],
    scale_factor_risks: [],
  },
};

// A check that read no settings reports no per-setting findings either, so only
// the table-level ones remain.
export const NoSettingsRead = Template.bind({});
NoSettingsRead.args = {
  config: {
    ...autovacuumConfig,
    settings: {},
    findings: autovacuumConfig.findings.filter((finding) => !finding.setting_name),
  },
};
