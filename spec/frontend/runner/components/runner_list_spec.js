import { GlTableLite, GlSkeletonLoader } from '@gitlab/ui';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerStatusPopover from '~/runner/components/runner_status_popover.vue';
import { allRunnersData, onlineContactTimeoutSecs, staleTimeoutSecs } from '../mock_data';

const mockRunners = allRunnersData.data.runners.nodes;
const mockActiveRunnersCount = mockRunners.length;

describe('RunnerList', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findHeaders = () => wrapper.findAll('th');
  const findRows = () => wrapper.findAll('[data-testid^="runner-row-"]');
  const findCell = ({ row = 0, fieldKey }) =>
    extendedWrapper(findRows().at(row).find(`[data-testid="td-${fieldKey}"]`));

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerList, {
      propsData: {
        runners: mockRunners,
        activeRunnersCount: mockActiveRunnersCount,
        ...props,
      },
      provide: {
        onlineContactTimeoutSecs,
        staleTimeoutSecs,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays headers', () => {
    createComponent(
      {
        stubs: {
          RunnerStatusPopover: {
            template: '<div/>',
          },
        },
      },
      mountExtended,
    );

    const headerLabels = findHeaders().wrappers.map((w) => w.text());

    expect(findHeaders().at(0).findComponent(RunnerStatusPopover).exists()).toBe(true);

    expect(headerLabels).toEqual([
      'Status',
      'Runner',
      'Version',
      'Jobs',
      'Tags',
      'Last contact',
      '', // actions has no label
    ]);
  });

  it('Sets runner id as a row key', () => {
    createComponent();

    expect(findTable().attributes('primary-key')).toBe('id');
  });

  it('Displays a list of runners', () => {
    createComponent({}, mountExtended);

    expect(findRows()).toHaveLength(4);

    expect(findSkeletonLoader().exists()).toBe(false);
  });

  it('Displays details of a runner', () => {
    const { id, description, version, shortSha } = mockRunners[0];

    createComponent({}, mountExtended);

    // Badges
    expect(findCell({ fieldKey: 'status' }).text()).toMatchInterpolatedText('never contacted');

    // Runner summary
    expect(findCell({ fieldKey: 'summary' }).text()).toContain(
      `#${getIdFromGraphQLId(id)} (${shortSha})`,
    );
    expect(findCell({ fieldKey: 'summary' }).text()).toContain(description);

    // Other fields
    expect(findCell({ fieldKey: 'version' }).text()).toBe(version);
    expect(findCell({ fieldKey: 'jobCount' }).text()).toBe('0');
    expect(findCell({ fieldKey: 'tagList' }).text()).toBe('');
    expect(findCell({ fieldKey: 'contactedAt' }).text()).toEqual(expect.any(String));

    // Actions
    expect(findCell({ fieldKey: 'actions' }).exists()).toBe(true);
  });

  describe('When the list is checkable', () => {
    beforeEach(() => {
      createComponent(
        {
          props: {
            checkable: true,
          },
        },
        mountExtended,
      );
    });

    it('Displays a checkbox field', () => {
      expect(findCell({ fieldKey: 'checkbox' }).find('input').exists()).toBe(true);
    });

    it('Emits a checked event', () => {
      const checkbox = findCell({ fieldKey: 'checkbox' }).find('input');

      checkbox.setChecked();

      expect(wrapper.emitted('checked')).toHaveLength(1);
      expect(wrapper.emitted('checked')[0][0]).toEqual({
        isChecked: true,
        runner: mockRunners[0],
      });
    });
  });

  describe('Scoped cell slots', () => {
    it('Render #runner-name slot in "summary" cell', () => {
      createComponent(
        {
          scopedSlots: { 'runner-name': ({ runner }) => `Summary: ${runner.id}` },
        },
        mountExtended,
      );

      expect(findCell({ fieldKey: 'summary' }).text()).toContain(`Summary: ${mockRunners[0].id}`);
    });

    it('Render #runner-actions-cell slot in "actions" cell', () => {
      createComponent(
        {
          scopedSlots: { 'runner-actions-cell': ({ runner }) => `Actions: ${runner.id}` },
        },
        mountExtended,
      );

      expect(findCell({ fieldKey: 'actions' }).text()).toBe(`Actions: ${mockRunners[0].id}`);
    });
  });

  describe('Table data formatting', () => {
    let mockRunnersCopy;

    beforeEach(() => {
      mockRunnersCopy = [
        {
          ...mockRunners[0],
        },
      ];
    });

    it('Formats job counts', () => {
      mockRunnersCopy[0].jobCount = 1;

      createComponent({ props: { runners: mockRunnersCopy } }, mountExtended);

      expect(findCell({ fieldKey: 'jobCount' }).text()).toBe('1');
    });

    it('Formats large job counts', () => {
      mockRunnersCopy[0].jobCount = 1000;

      createComponent({ props: { runners: mockRunnersCopy } }, mountExtended);

      expect(findCell({ fieldKey: 'jobCount' }).text()).toBe('1,000');
    });

    it('Formats large job counts with a plus symbol', () => {
      mockRunnersCopy[0].jobCount = 1001;

      createComponent({ props: { runners: mockRunnersCopy } }, mountExtended);

      expect(findCell({ fieldKey: 'jobCount' }).text()).toBe('1,000+');
    });
  });

  it('Shows runner identifier', () => {
    const { id, shortSha } = mockRunners[0];
    const numericId = getIdFromGraphQLId(id);

    createComponent({}, mountExtended);

    expect(findCell({ fieldKey: 'summary' }).text()).toContain(`#${numericId} (${shortSha})`);
  });

  describe('When data is loading', () => {
    it('shows a busy state', () => {
      createComponent({ props: { runners: [], loading: true } });

      expect(findTable().classes('gl-opacity-6')).toBe(true);
    });

    it('when there are no runners, shows an skeleton loader', () => {
      createComponent({ props: { runners: [], loading: true } }, mountExtended);

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('when there are runners, shows a busy indicator skeleton loader', () => {
      createComponent({ props: { loading: true } }, mountExtended);

      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
