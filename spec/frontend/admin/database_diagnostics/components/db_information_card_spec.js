import { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DbInformationCard from '~/admin/database_diagnostics/components/db_information_card.vue';
import DbSchemasSection from '~/admin/database_diagnostics/components/db_schemas_section.vue';
import DbTimeoutsSection from '~/admin/database_diagnostics/components/db_timeouts_section.vue';
import DiagnosticsSection from '~/admin/database_diagnostics/components/diagnostics_section.vue';
import {
  databaseInformationResults,
  databaseInformationWithDatabaseError,
  databaseInformationWithFindings,
} from '../mock_data';

describe('DbInformationCard component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);
  const findSchemasSection = () => wrapper.findComponent(DbSchemasSection);
  const findTimeoutsSection = () => wrapper.findComponent(DbTimeoutsSection);
  const findSearchPathSection = () => wrapper.findComponent(DiagnosticsSection);
  const findStatusIcon = () => wrapper.findComponentByTestId('search-path-status-icon');
  const findToggle = () => wrapper.findComponentByTestId('search-path-toggle');
  const findDetails = () => wrapper.findComponentByTestId('search-path-details');
  const findCountBadge = () => wrapper.findByTestId('search-path-count');
  const findCurrentUser = () => wrapper.findByTestId('current-user');
  const findSearchPath = () => wrapper.findByTestId('search-path');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(DbInformationCard, {
      propsData: {
        dbName: 'main',
        payload: databaseInformationResults.databases.main,
        ...props,
      },
    });
  };

  const expand = async () => {
    findToggle().vm.$emit('click');
    await nextTick();
  };

  describe('when the payload has no findings', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a green (success) status icon', () => {
      expect(findStatusIcon().props('variant')).toBe('success');
      expect(findStatusIcon().props('name')).toBe('check-circle-filled');
    });

    it('does not render a findings count badge', () => {
      expect(findCountBadge().exists()).toBe(false);
    });

    it('always renders the schemas table with the payload schemas', () => {
      expect(findSchemasSection().exists()).toBe(true);
      expect(findSchemasSection().props('schemas')).toEqual(
        databaseInformationResults.databases.main.schemas,
      );
    });

    it('renders the timeouts section with the payload timeouts', () => {
      expect(findTimeoutsSection().props('timeouts')).toEqual(
        databaseInformationResults.databases.main.timeouts,
      );
    });

    it('always offers a Details toggle but keeps the search path info collapsed by default', () => {
      expect(findToggle().exists()).toBe(true);
      expect(findDetails().props('visible')).toBe(false);
    });

    it('exposes the expanded state to assistive technology via aria attributes', async () => {
      expect(findToggle().attributes('aria-expanded')).toBe('false');
      expect(findToggle().attributes('aria-controls')).toBe(findDetails().attributes('id'));

      await expand();

      expect(findToggle().attributes('aria-expanded')).toBe('true');
    });

    it('reveals the current user and search path once expanded', async () => {
      await expand();

      const payload = databaseInformationResults.databases.main;
      expect(findDetails().props('visible')).toBe(true);
      expect(findCurrentUser().text()).toContain(payload.current_user);
      expect(findSearchPath().text()).toContain(payload.search_path);
    });

    it('collapses the search path info again when toggled a second time', async () => {
      await expand();
      expect(findDetails().props('visible')).toBe(true);

      await expand();
      expect(findDetails().props('visible')).toBe(false);
    });
  });

  describe('when the payload has findings', () => {
    beforeEach(() => {
      createComponent({ props: { payload: databaseInformationWithFindings.databases.main } });
    });

    it('reflects the worst severity in the status icon and shows the count', () => {
      // The fixture contains an error and a warning.
      expect(findStatusIcon().props('variant')).toBe('danger');
      expect(findStatusIcon().props('name')).toBe('error');
      expect(findCountBadge().text()).toBe('2');
    });

    it('renders one alert per finding with the mapped variant and message', () => {
      const alerts = findAllAlerts().wrappers;

      expect(alerts[0].props('variant')).toBe('danger');
      expect(alerts[0].text()).toBe('The public schema is not in the search path.');
      expect(alerts[1].props('variant')).toBe('warning');
      expect(alerts[1].text()).toBe(
        'The search path differs from the expected default of "$user", public.',
      );
    });

    it('passes the findings through in the order supplied, without reordering them', () => {
      // Ordering belongs to Gitlab::Database::Diagnostics::Checks::SchemaResolution.
      const findings = [
        { severity: 'warning', code: 'a_warning', message: 'a warning' },
        { severity: 'error', code: 'an_error', message: 'an error' },
      ];

      createComponent({
        props: {
          payload: {
            current_user: 'gitlab',
            search_path: 'public',
            schemas: [{ name: 'public', current: true, owner: 'postgres', has_tables: true }],
            findings,
            severity: 'error',
            counts: { error: 1, warning: 1 },
          },
        },
      });

      expect(findSearchPathSection().props('findings')).toEqual(findings);
    });
  });

  describe('when the payload has only warning findings', () => {
    beforeEach(() => {
      createComponent({
        props: {
          payload: {
            current_user: 'gitlab',
            search_path: 'public',
            schemas: [],
            findings: [{ severity: 'warning', code: 'a_warning', message: 'a warning' }],
            severity: 'warning',
            counts: { warning: 1 },
          },
        },
      });
    });

    it('renders a warning status icon', () => {
      expect(findStatusIcon().props('variant')).toBe('warning');
      expect(findStatusIcon().props('name')).toBe('warning');
    });
  });

  describe('when the payload has an error', () => {
    beforeEach(() => {
      createComponent({ props: { payload: databaseInformationWithDatabaseError.databases.main } });
    });

    it('renders a warning alert with the error message and no check sections', () => {
      expect(findAlert().props('variant')).toBe('warning');
      expect(findAlert().text()).toBe('connection refused');
      expect(findSearchPathSection().exists()).toBe(false);
      expect(findSchemasSection().exists()).toBe(false);
      expect(findTimeoutsSection().exists()).toBe(false);
    });
  });
});
