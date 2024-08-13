import { GlTableLite } from '@gitlab/ui';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';

import RunnerManagersTable from '~/ci/runner/components/runner_managers_table.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { I18N_STATUS_NEVER_CONTACTED } from '~/ci/runner/constants';

import { runnerManagersData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mockItems = runnerManagersData.data.runner.managers.nodes;

describe('RunnerJobs', () => {
  let wrapper;

  const findHeaders = () => wrapper.findAll('thead th');
  const findRows = () => wrapper.findAll('tbody tr');
  const findCell = ({ field, i }) => extendedWrapper(findRows().at(i)).findByTestId(`td-${field}`);
  const findCellText = (opts) => findCell(opts).text().replace(/\s+/g, ' ');

  const createComponent = ({ item } = {}) => {
    const [mockItem, ...otherItems] = mockItems;

    wrapper = mountExtended(RunnerManagersTable, {
      propsData: {
        items: [{ ...mockItem, ...item }, ...otherItems],
      },
      stubs: {
        GlTableLite,
      },
    });
  };

  it('shows headers', () => {
    createComponent();
    expect(findHeaders().wrappers.map((w) => w.text())).toEqual([
      expect.stringContaining('System ID'),
      'Status',
      'Version',
      'IP Address',
      'Executor',
      'Arch/Platform',
      'Last contact',
    ]);
  });

  it('shows rows', () => {
    createComponent();
    expect(findRows()).toHaveLength(2);
  });

  it('shows system id', () => {
    createComponent();
    expect(findCellText({ field: 'systemId', i: 0 })).toBe(mockItems[0].systemId);
    expect(findCellText({ field: 'systemId', i: 1 })).toBe(mockItems[1].systemId);
  });

  it('shows status', () => {
    createComponent();
    expect(findCellText({ field: 'status', i: 0 })).toContain('Online');
    expect(findCellText({ field: 'status', i: 0 })).toContain('Idle');
  });

  it('shows version', () => {
    createComponent({
      item: { version: '1.0' },
    });

    expect(findCellText({ field: 'version', i: 0 })).toBe('1.0');
  });

  it('shows version with revision', () => {
    createComponent({
      item: { version: '1.0', revision: '123456' },
    });

    expect(findCellText({ field: 'version', i: 0 })).toBe('1.0 (123456)');
  });

  it('shows revision without version', () => {
    createComponent({
      item: { version: null, revision: '123456' },
    });

    expect(findCellText({ field: 'version', i: 0 })).toBe('(123456)');
  });

  it('shows ip address', () => {
    createComponent({
      item: { ipAddress: '127.0.0.1' },
    });

    expect(findCellText({ field: 'ipAddress', i: 0 })).toBe('127.0.0.1');
  });

  it('shows executor', () => {
    createComponent({
      item: { executorName: 'shell' },
    });

    expect(findCellText({ field: 'executorName', i: 0 })).toBe('shell');
  });

  it('shows architecture', () => {
    createComponent({
      item: { architectureName: 'x64' },
    });

    expect(findCellText({ field: 'architecturePlatform', i: 0 })).toBe('x64');
  });

  it('shows platform', () => {
    createComponent({
      item: { platformName: 'darwin' },
    });

    expect(findCellText({ field: 'architecturePlatform', i: 0 })).toBe('darwin');
  });

  it('shows architecture and platform', () => {
    createComponent({
      item: { architectureName: 'x64', platformName: 'darwin' },
    });

    expect(findCellText({ field: 'architecturePlatform', i: 0 })).toBe('x64/darwin');
  });

  it('shows contacted at', () => {
    createComponent();
    expect(findCell({ field: 'contactedAt', i: 0 }).findComponent(TimeAgo).props('time')).toBe(
      mockItems[0].contactedAt,
    );
  });

  it('shows missing contacted at', () => {
    createComponent({
      item: { contactedAt: null },
    });
    expect(findCellText({ field: 'contactedAt', i: 0 })).toBe(I18N_STATUS_NEVER_CONTACTED);
  });
});
