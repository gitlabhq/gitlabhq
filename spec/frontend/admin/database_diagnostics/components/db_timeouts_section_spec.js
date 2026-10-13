import { nextTick } from 'vue';
import { GlAlert, GlLink, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DbTimeoutsSection from '~/admin/database_diagnostics/components/db_timeouts_section.vue';
import { timeouts, timeoutsSettings, timeoutsWithoutFindings } from '../mock_data';

describe('DbTimeoutsSection component', () => {
  let wrapper;

  const findStatusIcon = () => wrapper.findComponentByTestId('timeouts-status-icon');
  const findCountBadge = () => wrapper.findByTestId('timeouts-count');
  const findToggle = () => wrapper.findComponentByTestId('timeouts-toggle');
  const findCollapse = () => wrapper.findComponentByTestId('timeouts-details');
  const findEmpty = () => wrapper.findByTestId('timeouts-empty');
  const findSettingsTable = () => wrapper.findComponentByTestId('timeouts-settings-table');
  const findOverridesTable = () => wrapper.findComponentByTestId('timeouts-overrides-table');
  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);
  const findDocsLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(DbTimeoutsSection, {
      propsData: {
        timeouts: timeoutsWithoutFindings,
        ...props,
      },
    });
  };

  const expand = async () => {
    findToggle().vm.$emit('click');
    await nextTick();
  };

  describe('when there are no findings', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a green status icon and no count badge', () => {
      expect(findStatusIcon().props('variant')).toBe('success');
      expect(findStatusIcon().props('name')).toBe('check-circle-filled');
      expect(findCountBadge().exists()).toBe(false);
    });

    it('keeps the details collapsed until toggled', async () => {
      expect(findCollapse().props('visible')).toBe(false);

      await expand();

      expect(findCollapse().props('visible')).toBe(true);
    });

    it('exposes the expanded state to assistive technology', async () => {
      expect(findToggle().attributes('aria-expanded')).toBe('false');
      expect(findToggle().attributes('aria-controls')).toBe(findCollapse().attributes('id'));

      await expand();

      expect(findToggle().attributes('aria-expanded')).toBe('true');
    });

    it('renders one row per setting, in the order the backend supplied', () => {
      expect(
        findSettingsTable()
          .props('items')
          .map((item) => item.name),
      ).toEqual(Object.keys(timeoutsSettings));
    });

    it('renders a value with its unit, and zero as unlimited', () => {
      const [statementTimeout, lockTimeout] = findSettingsTable().props('items');

      expect(statementTimeout.session).toBe('120000 ms');
      expect(statementTimeout.clusterDefault).toBe('unlimited');
      expect(lockTimeout.session).toBe('unlimited');
    });

    it('renders the source without a location when the setting has none', () => {
      expect(findSettingsTable().props('items')[0].source).toBe('session');
    });

    it('omits the role and database defaults table', () => {
      expect(findOverridesTable().exists()).toBe(false);
    });

    it('links to the documented timeout settings', () => {
      expect(findDocsLink().attributes('href')).toBe(
        '/help/administration/postgresql/tune#required-settings-for-external-instances',
      );
    });
  });

  describe('when there are findings', () => {
    beforeEach(() => {
      createComponent({ props: { timeouts } });
    });

    it('reflects the severity in the status icon and shows the count', () => {
      expect(findStatusIcon().props('variant')).toBe('warning');
      expect(findStatusIcon().props('name')).toBe('warning');
      expect(findCountBadge().text()).toBe('1');
    });

    it('renders one alert per finding with the mapped variant', () => {
      const alerts = findAllAlerts().wrappers;

      expect(alerts).toHaveLength(1);
      expect(alerts[0].props('variant')).toBe('warning');
      expect(alerts[0].text()).toBe('The cluster default for statement_timeout is 0.');
    });

    it('renders a danger status icon for an error severity', () => {
      createComponent({
        props: {
          timeouts: {
            ...timeouts,
            findings: [{ severity: 'error', code: 'statement_timeout_unlimited', message: 'boom' }],
            severity: 'error',
          },
        },
      });

      expect(findStatusIcon().props('variant')).toBe('danger');
      expect(findAllAlerts().at(0).props('variant')).toBe('danger');
    });
  });

  describe('when a setting comes from a configuration file', () => {
    beforeEach(() => {
      createComponent({
        props: {
          timeouts: {
            ...timeoutsWithoutFindings,
            settings: {
              statement_timeout: {
                value: 60000,
                default_value: 60000,
                unit: 'ms',
                source: 'configuration file',
                source_location: '/etc/postgresql/postgresql.conf:750',
              },
            },
          },
        },
      });
    });

    it('renders the file and line next to the source', () => {
      expect(findSettingsTable().props('items')[0].source).toBe(
        'configuration file (/etc/postgresql/postgresql.conf:750)',
      );
    });
  });

  describe('with role and database defaults', () => {
    beforeEach(() => {
      createComponent({
        props: {
          timeouts: {
            ...timeoutsWithoutFindings,
            overrides: [
              {
                database_name: null,
                role_name: null,
                name: 'statement_timeout',
                value: '90s',
              },
              {
                database_name: 'gitlabhq',
                role_name: 'gitlab',
                name: 'lock_timeout',
                value: '5s',
              },
            ],
          },
        },
      });
    });

    it('renders a second table, marking a missing role or database as All', () => {
      expect(findOverridesTable().props('items')).toEqual([
        { role: 'All', database: 'All', name: 'statement_timeout', value: '90s' },
        { role: 'gitlab', database: 'gitlabhq', name: 'lock_timeout', value: '5s' },
      ]);
    });
  });

  describe('when no settings could be read', () => {
    beforeEach(() => {
      createComponent({
        props: { timeouts: { ...timeoutsWithoutFindings, settings: {} } },
      });
    });

    it('renders an empty message instead of the tables and the toggle', () => {
      expect(findEmpty().exists()).toBe(true);
      expect(findToggle().exists()).toBe(false);
      expect(wrapper.findComponent(GlTableLite).exists()).toBe(false);
    });
  });
});
