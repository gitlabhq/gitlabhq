import { mount } from '@vue/test-utils';
import { GlTable, GlLoadingIcon } from '@gitlab/ui';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';

const mockAlert = {
  iid: '1527542',
  title: 'SyntaxError: Invalid or unexpected token',
  severity: 'CRITICAL',
  eventCount: 7,
  createdAt: '2020-04-17T23:18:14.996Z',
  startedAt: '2020-04-17T23:18:14.996Z',
  endedAt: '2020-04-17T23:18:14.996Z',
  status: 'TRIGGERED',
  assignees: { nodes: [] },
  notes: { nodes: [] },
  todos: { nodes: [] },
};

describe('AlertDetails', () => {
  let wrapper;

  function mountComponent(propsData = {}) {
    wrapper = mount(AlertDetailsTable, {
      propsData: {
        alert: mockAlert,
        loading: false,
        ...propsData,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTableComponent = () => wrapper.find(GlTable);

  describe('Alert details', () => {
    describe('empty state', () => {
      beforeEach(() => {
        mountComponent({ alert: null });
      });

      it('shows an empty state when no alert is provided', () => {
        expect(wrapper.text()).toContain('No alert data to display.');
      });
    });

    describe('loading state', () => {
      beforeEach(() => {
        mountComponent({ loading: true });
      });

      it('displays a loading state when loading', () => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      });
    });

    describe('with table data', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('renders a table', () => {
        expect(findTableComponent().exists()).toBe(true);
      });

      it('renders a cell based on alert data', () => {
        expect(findTableComponent().text()).toContain('SyntaxError: Invalid or unexpected token');
      });
    });
  });
});
