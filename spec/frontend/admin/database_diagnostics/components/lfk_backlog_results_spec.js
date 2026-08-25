import { GlTableLite, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LfkBacklogResults from '~/admin/database_diagnostics/components/lfk_backlog_results.vue';
import { lfkBacklogResults } from '../mock_data';

describe('LfkBacklogResults component', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findNoBacklog = () => wrapper.findByTestId('lfk-no-backlog');

  const createComponent = (props) => {
    wrapper = mountExtended(LfkBacklogResults, {
      propsData: {
        connectionName: 'main',
        ...props,
      },
    });
  };

  describe('with a backlog', () => {
    beforeEach(() => {
      createComponent({ backlog: lfkBacklogResults.connections.main });
    });

    it('renders the connection name and a warning icon', () => {
      expect(wrapper.text()).toContain('main');
      expect(findIcon().props('name')).toBe('warning');
    });

    it('renders a table row per parent table with a humanized age', () => {
      const rows = findTable().findAll('tbody tr');
      expect(rows).toHaveLength(2);

      const firstRow = rows.at(0).text();
      expect(firstRow).toContain('public.projects');
      expect(firstRow).toContain('100000');
      // 50,000,000 seconds humanizes to a count of days
      expect(firstRow).toContain('days');
    });

    it('appends "+" to a capped pending count only', () => {
      // public.projects is capped -> "100000+"; public.users is exact (no marker)
      expect(wrapper.text()).toContain('100000+');
      expect(wrapper.findAllByTestId('pending-capped')).toHaveLength(1);
    });
  });

  describe('with no backlog', () => {
    beforeEach(() => {
      createComponent({ backlog: [] });
    });

    it('renders a success icon and an empty-state message', () => {
      expect(findIcon().props('name')).toBe('check-circle-filled');
      expect(findNoBacklog().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });
  });
});
