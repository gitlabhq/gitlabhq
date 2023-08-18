import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TracingTableList from '~/tracing/components/tracing_table_list.vue';

describe('TracingTableList', () => {
  let wrapper;
  const mockTraces = [
    {
      timestamp: '2023-07-10T15:02:30.677538Z',
      service_name: 'tracegen',
      operation: 'lets-go',
      duration_nano: 150000,
    },
    {
      timestamp: '2023-07-10T15:02:30.677538Z',
      service_name: 'tracegen',
      operation: 'lets-go',
      duration_nano: 200000,
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
  const getRow = (idx) => getRows().at(idx);
  const getCells = (trIdx) => getRows().at(trIdx).findAll('td');

  const getCell = (trIdx, tdIdx) => {
    return getCells(trIdx).at(tdIdx);
  };

  const selectRow = async (idx) => {
    getRow(idx).trigger('click');
    await nextTick();
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
      expect(getCell(i, 3).text()).toBe(`${trace.duration_nano / 1000} ms`);
    });
  });

  it('emits trace-selected on row selection', async () => {
    mountComponent();

    await selectRow(0);
    expect(wrapper.emitted('trace-selected')).toHaveLength(1);
    expect(wrapper.emitted('trace-selected')[0][0]).toEqual({ trace_id: mockTraces[0].trace_id });
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
