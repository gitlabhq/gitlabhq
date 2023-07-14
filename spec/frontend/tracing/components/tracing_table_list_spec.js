import { mountExtended } from 'helpers/vue_test_utils_helper';
import TracingTableList from '~/tracing/components/tracing_table_list.vue';

describe('TracingTableList', () => {
  let wrapper;
  const mockTraces = [
    {
      timestamp: '2023-07-10T15:02:30.677538Z',
      service_name: 'tracegen',
      operation: 'lets-go',
      duration: 150,
    },
    {
      timestamp: '2023-07-10T15:02:30.677538Z',
      service_name: 'tracegen',
      operation: 'lets-go',
      duration: 200,
    },
  ];

  const mountComponent = ({ traces = mockTraces } = {}) => {
    wrapper = mountExtended(TracingTableList, {
      propsData: {
        traces,
      },
    });
  };

  const getRows = () => wrapper.findComponent({ name: 'GlTable' }).find('tbody').findAll('tr');

  const getCells = (trIdx) => getRows().at(trIdx).findAll('td');

  const getCell = (trIdx, tdIdx) => {
    return getCells(trIdx).at(tdIdx);
  };

  it('renders traces as table', () => {
    mountComponent();

    const rows = wrapper.findAll('table tbody tr');

    expect(rows.length).toBe(mockTraces.length);

    mockTraces.forEach((trace, i) => {
      expect(getCells(i).length).toBe(4);
      expect(getCell(i, 0).text()).toBe(trace.timestamp);
      expect(getCell(i, 1).text()).toBe(trace.service_name);
      expect(getCell(i, 2).text()).toBe(trace.operation);
      expect(getCell(i, 3).text()).toBe(`${trace.duration} ms`);
    });
  });

  it('renders the empty state when no traces are provided', () => {
    mountComponent({ traces: [] });

    expect(getCell(0, 0).text()).toContain('No traces to display');
    const link = getCell(0, 0).findComponent({ name: 'GlLink' });
    expect(link.text()).toBe('Check again');

    link.trigger('click');
    expect(wrapper.emitted('reload')).toHaveLength(1);
  });
});
