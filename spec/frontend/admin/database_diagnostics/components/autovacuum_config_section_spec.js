import { mountExtended } from 'helpers/vue_test_utils_helper';
import AutovacuumConfigSection from '~/admin/database_diagnostics/components/autovacuum_config_section.vue';
import { autovacuumConfig } from '../mock_data';

describe('AutovacuumConfigSection component', () => {
  let wrapper;

  const findSettingsEmpty = () => wrapper.findByTestId('settings-empty');
  const findOverridesTable = () => wrapper.findByTestId('overrides-table');
  const findScaleFactorRisks = () => wrapper.findByTestId('scale-factor-risks');
  const findStatus = (name) => wrapper.findByTestId(`status-${name}`);
  const findSettingsDetails = () => wrapper.findComponentByTestId('settings-details');
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

  describe('table-level findings', () => {
    it('shows an alert per finding that has no setting_name', () => {
      createComponent();

      expect(wrapper.findByTestId('table-finding-tables_autovacuum_disabled').text()).toBe(
        'Autovacuum is disabled for 1 table.',
      );
      expect(wrapper.findByTestId('table-finding-scale_factor_risk').text()).toBe(
        'The global vacuum scale factor is high for 1 large table.',
      );
    });

    it('shows no alert for a finding tied to a setting', () => {
      createComponent({
        config: configWithFinding({
          severity: 'warning',
          code: 'autovacuum_work_mem_inherited',
          setting_name: 'autovacuum_work_mem',
          message: 'Inherited.',
        }),
      });

      expect(wrapper.findByTestId('table-finding-autovacuum_work_mem_inherited').exists()).toBe(
        false,
      );
    });
  });

  describe('per-table overrides', () => {
    const findOverridesToggle = () => wrapper.findByTestId('overrides-toggle');
    const findOverridesDetails = () => wrapper.findComponentByTestId('overrides-details');
    const findOverridesStatusIcon = () => wrapper.findComponentByTestId('overrides-status-icon');
    const expandOverrides = () => findOverridesToggle().trigger('click');

    it('renders nothing at all when there are no overrides', () => {
      createComponent({ config: { ...autovacuumConfig, table_overrides: [] } });

      expect(findOverridesToggle().exists()).toBe(false);
      expect(findOverridesTable().exists()).toBe(false);
    });

    it('is collapsed by default but keeps the details element in the DOM', () => {
      createComponent();

      expect(findOverridesToggle().exists()).toBe(true);
      expect(findOverridesDetails().props('visible')).toBe(false);
      expect(wrapper.findByTestId('overrides-count').text()).toBe('3');
    });

    it('expands and collapses when the toggle is clicked', async () => {
      createComponent();

      await expandOverrides();
      expect(findOverridesDetails().props('visible')).toBe(true);

      await expandOverrides();
      expect(findOverridesDetails().props('visible')).toBe(false);
    });

    describe('when expanded', () => {
      beforeEach(async () => {
        createComponent();
        await expandOverrides();
      });

      it('lists each table that overrides autovacuum settings', () => {
        expect(findOverridesTable().text()).toContain('public.ci_builds');
        expect(findOverridesTable().text()).toContain('autovacuum_vacuum_scale_factor=0.01');
      });

      it('formats the size and the estimated row count', () => {
        expect(findOverridesTable().text()).toContain('5.00 GiB');
        expect(findOverridesTable().text()).toContain('2.00 TiB');
        expect(findOverridesTable().text()).toContain('(~1,000,000 rows)');
      });

      it('flags only the table that disables autovacuum', () => {
        const badges = wrapper.findAllByTestId('table-disabled-badge');

        expect(badges).toHaveLength(1);
        expect(badges.at(0).text()).toBe('Autovacuum disabled');
      });
    });

    describe('status icon', () => {
      it('shows a danger icon when a table disables autovacuum', () => {
        createComponent();

        expect(findOverridesStatusIcon().props('name')).toBe('error');
      });

      it('shows a green tick when no table disables autovacuum', () => {
        createComponent({
          config: { ...autovacuumConfig, table_overrides: [autovacuumConfig.table_overrides[0]] },
        });

        expect(findOverridesStatusIcon().props('name')).toBe('check-circle-filled');
      });
    });
  });

  describe('scale factor risk', () => {
    it('lists the tables the backend reported as risks', () => {
      createComponent();

      expect(findScaleFactorRisks().exists()).toBe(true);
      expect(findScaleFactorRisks().text()).toContain('public.merge_request_diffs');
    });

    it('is hidden when the backend reported no risks', () => {
      createComponent({ config: { ...autovacuumConfig, scale_factor_risks: [] } });

      expect(findScaleFactorRisks().exists()).toBe(false);
    });
  });
});
