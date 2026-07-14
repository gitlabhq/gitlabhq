import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DbVacuumSection from '~/admin/database_diagnostics/components/db_vacuum_section.vue';
import { vacuumActivity } from '../mock_data';

describe('DbVacuumSection component', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findEmptyState = () => wrapper.findByTestId('vacuum-empty');
  const findRows = () => wrapper.findAll('tbody tr');

  const createComponent = ({ vacuums = vacuumActivity } = {}) => {
    wrapper = mountExtended(DbVacuumSection, {
      propsData: { vacuums },
    });
  };

  describe('when no vacuum is running', () => {
    beforeEach(() => {
      createComponent({ vacuums: [] });
    });

    it('renders the empty state instead of the table', () => {
      expect(findEmptyState().text()).toBe('No vacuum operations are currently running.');
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('with in-progress vacuums', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a row per vacuum', () => {
      expect(findTable().exists()).toBe(true);
      expect(findRows()).toHaveLength(vacuumActivity.length);
    });

    it('renders the qualified table name', () => {
      expect(findRows().at(0).text()).toContain('public.ci_builds');
    });

    it('renders heap progress as a percentage with raw block counts', () => {
      expect(findRows().at(0).text()).toContain('60%');
      expect(findRows().at(0).text()).toContain('600 / 1000');
    });

    it('formats dead-tuple byte counts as human-readable sizes', () => {
      expect(findRows().at(0).text()).toContain('1.91 MiB');
    });

    it('flags rows under memory pressure (more than one index pass) only', () => {
      // First row has index_vacuum_count: 2, second has 0.
      expect(findRows().at(0).text()).toContain('Memory pressure');
      expect(findRows().at(1).text()).not.toContain('Memory pressure');
    });

    it('renders the vacuum type for each row', () => {
      expect(findRows().at(0).text()).toContain('Autovacuum');
      expect(findRows().at(1).text()).toContain('Manual VACUUM');
    });

    it('renders the running duration for each row', () => {
      expect(findRows().at(0).text()).toContain('about 10 hours');
      expect(findRows().at(1).text()).toContain('5 minutes');
    });

    it('flags only vacuums running longer than the threshold', () => {
      // First row has run for 36000s (> 6h), second for 300s.
      expect(findRows().at(0).text()).toContain('Long-running');
      expect(findRows().at(1).text()).not.toContain('Long-running');
    });

    it('orders rows by running time (longest first) then table name', () => {
      createComponent({
        vacuums: [
          { ...vacuumActivity[1], table_name: 'zebra', running_time_seconds: 100 },
          { ...vacuumActivity[1], table_name: 'alpha', running_time_seconds: 100 },
          { ...vacuumActivity[0], table_name: 'beta', running_time_seconds: 5000 },
        ],
      });

      const tables = findRows().wrappers.map((row) => row.find('code').text());

      expect(tables).toEqual(['public.beta', 'public.alpha', 'public.zebra']);
    });

    it('renders delay_time when present and a fallback when null', () => {
      expect(findRows().at(0).text()).toContain('12.5 ms');
      expect(findRows().at(1).text()).toContain('Not available');
    });
  });

  describe('anti-wraparound vacuums', () => {
    it('does not flag ordinary vacuums', () => {
      createComponent();

      expect(wrapper.findByTestId('anti-wraparound-badge').exists()).toBe(false);
    });

    it('flags a vacuum running to prevent transaction ID wraparound', () => {
      createComponent({
        vacuums: [{ ...vacuumActivity[0], anti_wraparound: true }],
      });

      const badge = wrapper.findByTestId('anti-wraparound-badge');
      expect(badge.exists()).toBe(true);
      expect(badge.text()).toBe('Anti-wraparound');
    });
  });
});
