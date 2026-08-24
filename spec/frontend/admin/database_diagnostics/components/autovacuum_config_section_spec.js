import { GlCollapse } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AutovacuumConfigSection from '~/admin/database_diagnostics/components/autovacuum_config_section.vue';
import { autovacuumConfig } from '../mock_data';

describe('AutovacuumConfigSection component', () => {
  let wrapper;

  const findSettingsEmpty = () => wrapper.findByTestId('settings-empty');
  const findStatus = (name) => wrapper.findByTestId(`status-${name}`);
  const findSettingsDetails = () => wrapper.findComponent(GlCollapse);
  const findStatusIcon = () => wrapper.findComponentByTestId('settings-status-icon');
  const findSettingsToggle = () => wrapper.findByTestId('settings-toggle');
  const expandSettings = () => findSettingsToggle().trigger('click');
  const findRowValue = (name) => {
    const row = wrapper.findAll('tbody tr').wrappers.find((tr) => tr.find('code').text() === name);

    return row.findAll('td').at(1).text();
  };

  // Settings with every flaggable value moved to a healthy value.
  const healthyConfig = {
    ...autovacuumConfig,
    settings: {
      ...autovacuumConfig.settings,
      autovacuum_vacuum_cost_limit: { value: '2000', unit: null },
      autovacuum_work_mem: { value: '1048576', unit: 'kB' },
    },
  };

  const configWithSettings = (settings) => ({
    ...autovacuumConfig,
    settings: { ...autovacuumConfig.settings, ...settings },
  });

  const createComponent = ({ config = autovacuumConfig } = {}) => {
    wrapper = mountExtended(AutovacuumConfigSection, {
      propsData: { config },
    });
  };

  describe('effective settings', () => {
    beforeEach(async () => {
      createComponent();
      await expandSettings();
    });

    it('renders a row per known setting present in the config', () => {
      expect(wrapper.findAll('tbody tr').at(0).text()).toContain('autovacuum');
      expect(wrapper.text()).toContain('autovacuum_freeze_max_age');
    });

    it('appends the unit to values that have one', () => {
      expect(findRowValue('maintenance_work_mem')).toBe('65536 kB');
    });

    it('renders the -1 "not set" sentinel without the unit', () => {
      expect(findRowValue('autovacuum_work_mem')).toBe('-1');
    });

    it('flags fewer workers than the default as low', async () => {
      createComponent({
        config: configWithSettings({ autovacuum_max_workers: { value: '2', unit: null } }),
      });
      await expandSettings();

      expect(findStatus('autovacuum_max_workers').text()).toBe('Low');
    });

    it('does not flag the default worker count', () => {
      expect(findStatus('autovacuum_max_workers').exists()).toBe(false);
      expect(wrapper.findByTestId('status-ok-autovacuum_max_workers').text()).toBe('OK');
    });

    it('flags an inherited cost limit at the default as low', () => {
      expect(findStatus('autovacuum_vacuum_cost_limit').text()).toBe('Low');
    });

    it('shows the effective value next to an inherited cost limit', () => {
      expect(findRowValue('autovacuum_vacuum_cost_limit')).toBe('-1 (effective: 200)');
    });

    it('does not flag an inherited cost limit when vacuum_cost_limit is raised', async () => {
      createComponent({
        config: configWithSettings({ vacuum_cost_limit: { value: '2000', unit: null } }),
      });
      await expandSettings();

      expect(findStatus('autovacuum_vacuum_cost_limit').exists()).toBe(false);
      expect(findRowValue('autovacuum_vacuum_cost_limit')).toBe('-1 (effective: 2000)');
    });

    it('does not flag an explicit cost limit above the default', async () => {
      createComponent({
        config: configWithSettings({
          autovacuum_vacuum_cost_limit: { value: '2000', unit: null },
        }),
      });
      await expandSettings();

      expect(findStatus('autovacuum_vacuum_cost_limit').exists()).toBe(false);
      expect(findRowValue('autovacuum_vacuum_cost_limit')).toBe('2000');
    });

    it('flags an unset work_mem as inherited', () => {
      expect(findStatus('autovacuum_work_mem').text()).toBe('Inherited');
    });

    it('shows an OK badge for a healthy setting', () => {
      expect(findStatus('autovacuum_naptime').exists()).toBe(false);
      expect(wrapper.findByTestId('status-ok-autovacuum_naptime').text()).toBe('OK');
    });

    it('flags autovacuum_vacuum_cost_delay = 0 as throttling disabled', async () => {
      createComponent({
        config: configWithSettings({ autovacuum_vacuum_cost_delay: { value: '0', unit: 'ms' } }),
      });
      await expandSettings();

      expect(findStatus('autovacuum_vacuum_cost_delay').text()).toBe('Throttling disabled');
    });

    it('flags autovacuum globally off as disabled', async () => {
      createComponent({ config: configWithSettings({ autovacuum: { value: 'off', unit: null } }) });
      await expandSettings();

      expect(findStatus('autovacuum').text()).toBe('Disabled');
    });

    it('renders an empty state without a status icon or toggle when no settings could be read', () => {
      createComponent({ config: {} });

      expect(findSettingsEmpty().text()).toBe('No autovacuum settings could be read.');
      expect(findStatusIcon().exists()).toBe(false);
      expect(findSettingsToggle().exists()).toBe(false);
    });
  });

  describe('folding', () => {
    it('is collapsed by default but keeps the details element in the DOM', () => {
      createComponent();

      expect(findSettingsDetails().exists()).toBe(true);
      expect(findSettingsDetails().props('visible')).toBe(false);
    });

    it('expands and collapses when the toggle is clicked', async () => {
      createComponent();

      await expandSettings();
      expect(findSettingsDetails().props('visible')).toBe(true);

      await expandSettings();
      expect(findSettingsDetails().props('visible')).toBe(false);
    });

    it('shows a warning icon and the flagged count when settings have warnings', () => {
      createComponent();

      expect(findStatusIcon().props('name')).toBe('warning');
      expect(wrapper.findByTestId('settings-flagged-count').text()).toBe('2');
    });

    it('shows a danger icon when a setting is critical', () => {
      createComponent({
        config: configWithSettings({ autovacuum_vacuum_cost_delay: { value: '0', unit: 'ms' } }),
      });

      expect(findStatusIcon().props('name')).toBe('error');
    });

    it('shows a green tick and no count when all settings are healthy', () => {
      createComponent({ config: healthyConfig });

      expect(findStatusIcon().props('name')).toBe('check-circle-filled');
      expect(wrapper.findByTestId('settings-flagged-count').exists()).toBe(false);
    });
  });
});
