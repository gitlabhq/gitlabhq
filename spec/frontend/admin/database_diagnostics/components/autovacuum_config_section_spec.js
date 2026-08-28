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

  const healthyConfig = {
    ...autovacuumConfig,
    findings: [],
    severity: null,
    counts: {},
  };

  const configWithFinding = (finding) => ({
    ...autovacuumConfig,
    findings: [finding],
    severity: finding.severity,
    counts: { [finding.severity]: 1 },
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

    it('renders a row per setting supplied by the backend', () => {
      expect(wrapper.findAll('tbody tr').at(0).text()).toContain('autovacuum');
      expect(wrapper.text()).toContain('autovacuum_freeze_max_age');
    });

    it('appends the unit to values that have one', () => {
      expect(findRowValue('maintenance_work_mem')).toBe('65536 kB');
    });

    it('renders the -1 "not set" sentinel without the unit', () => {
      expect(findRowValue('autovacuum_work_mem')).toBe('-1');
    });

    it('shows the resolved value the backend annotated on an inherited cost limit', () => {
      expect(findRowValue('autovacuum_vacuum_cost_limit')).toBe('-1 (effective: 200)');
    });

    it.each`
      code                                | severity     | settingName                       | label
      ${'autovacuum_disabled'}            | ${'error'}   | ${'autovacuum'}                   | ${'Disabled'}
      ${'autovacuum_throttling_disabled'} | ${'error'}   | ${'autovacuum_vacuum_cost_delay'} | ${'Throttling disabled'}
      ${'autovacuum_max_workers_low'}     | ${'warning'} | ${'autovacuum_max_workers'}       | ${'Low'}
      ${'autovacuum_cost_limit_low'}      | ${'warning'} | ${'autovacuum_vacuum_cost_limit'} | ${'Low'}
      ${'autovacuum_work_mem_inherited'}  | ${'warning'} | ${'autovacuum_work_mem'}          | ${'Inherited'}
    `(
      'labels a $code finding "$label" on its setting row',
      async ({ code, severity, settingName, label }) => {
        createComponent({
          config: configWithFinding({
            severity,
            code,
            setting_name: settingName,
            message: 'Explanation from the backend.',
          }),
        });
        await expandSettings();

        expect(findStatus(settingName).text()).toBe(label);
        expect(findStatus(settingName).attributes('title')).toBe('Explanation from the backend.');
      },
    );

    it('falls back to a severity label for an unknown finding code', async () => {
      createComponent({
        config: configWithFinding({
          severity: 'warning',
          code: 'some_new_backend_check',
          setting_name: 'autovacuum_naptime',
          message: 'New check.',
        }),
      });
      await expandSettings();

      expect(findStatus('autovacuum_naptime').text()).toBe('Warning');
    });

    it('shows an OK badge for a setting without a finding', () => {
      expect(findStatus('autovacuum_naptime').exists()).toBe(false);
      expect(wrapper.findByTestId('status-ok-autovacuum_naptime').text()).toBe('OK');
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

    it('shows a warning icon and the flagged count when the check reported warnings', () => {
      createComponent();

      expect(findStatusIcon().props('name')).toBe('warning');
      expect(wrapper.findByTestId('settings-flagged-count').text()).toBe('2');
    });

    it('shows a danger icon when the check reported an error', () => {
      createComponent({
        config: configWithFinding({
          severity: 'error',
          code: 'autovacuum_disabled',
          setting_name: 'autovacuum',
          message: 'Autovacuum is disabled.',
        }),
      });

      expect(findStatusIcon().props('name')).toBe('error');
    });

    it('shows a green tick and no count when the check reported nothing', () => {
      createComponent({ config: healthyConfig });

      expect(findStatusIcon().props('name')).toBe('check-circle-filled');
      expect(wrapper.findByTestId('settings-flagged-count').exists()).toBe(false);
    });
  });
});
