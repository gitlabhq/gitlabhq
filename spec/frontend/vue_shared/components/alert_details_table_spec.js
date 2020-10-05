import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
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
  __typename: 'AlertManagementAlert',
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
  const findTableKeys = () => findTableComponent().findAll('tbody td:first-child');
  const findTableField = (fields, fieldName) => fields.filter(row => row.text() === fieldName);

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
      const environment = 'myEnvironment';
      const environmentUrl = 'fake/url';
      beforeEach(() => {
        mountComponent({ alert: { ...mockAlert, environment, environmentUrl } });
      });

      it('renders a table', () => {
        expect(findTableComponent().exists()).toBe(true);
      });

      it('renders a cell based on alert data', () => {
        expect(findTableComponent().text()).toContain('SyntaxError: Invalid or unexpected token');
      });

      it('should show allowed alert fields', () => {
        const fields = findTableKeys();

        expect(findTableField(fields, 'Iid').exists()).toBe(true);
        expect(findTableField(fields, 'Title').exists()).toBe(true);
        expect(findTableField(fields, 'Severity').exists()).toBe(true);
        expect(findTableField(fields, 'Status').exists()).toBe(true);
        expect(findTableField(fields, 'Environment').exists()).toBe(true);
      });

      it('should not show disallowed alert fields', () => {
        const fields = findTableKeys();

        expect(findTableField(fields, 'Typename').exists()).toBe(false);
        expect(findTableField(fields, 'Todos').exists()).toBe(false);
        expect(findTableField(fields, 'Notes').exists()).toBe(false);
        expect(findTableField(fields, 'Assignees').exists()).toBe(false);
        expect(findTableField(fields, 'EnvironmentUrl').exists()).toBe(false);
      });
    });
  });
});
