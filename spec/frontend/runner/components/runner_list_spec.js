import { GlTable, GlSkeletonLoader } from '@gitlab/ui';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerEditButton from '~/runner/components/runner_edit_button.vue';
import { runnersData } from '../mock_data';

const mockRunners = runnersData.data.runners.nodes;
const mockActiveRunnersCount = mockRunners.length;

describe('RunnerList', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => wrapper.findAll('th');
  const findRows = () => wrapper.findAll('[data-testid^="runner-row-"]');
  const findCell = ({ row = 0, fieldKey }) =>
    extendedWrapper(findRows().at(row).find(`[data-testid="td-${fieldKey}"]`));

  const createComponent = ({ props = {} } = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerList, {
      propsData: {
        runners: mockRunners,
        activeRunnersCount: mockActiveRunnersCount,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent({}, mountExtended);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays headers', () => {
    const headerLabels = findHeaders().wrappers.map((w) => w.text());

    expect(headerLabels).toEqual([
      'Status',
      'Runner ID',
      'Version',
      'IP Address',
      'Jobs',
      'Tags',
      'Last contact',
      '', // actions has no label
    ]);
  });

  it('Sets runner id as a row key', () => {
    createComponent({});

    expect(findTable().attributes('primary-key')).toBe('id');
  });

  it('Displays a list of runners', () => {
    expect(findRows()).toHaveLength(4);

    expect(findSkeletonLoader().exists()).toBe(false);
  });

  it('Displays details of a runner', () => {
    const { id, description, version, ipAddress, shortSha } = mockRunners[0];

    // Badges
    expect(findCell({ fieldKey: 'status' }).text()).toMatchInterpolatedText(
      'never contacted paused',
    );

    // Runner summary
    expect(findCell({ fieldKey: 'summary' }).text()).toContain(
      `#${getIdFromGraphQLId(id)} (${shortSha})`,
    );
    expect(findCell({ fieldKey: 'summary' }).text()).toContain(description);

    // Other fields
    expect(findCell({ fieldKey: 'version' }).text()).toBe(version);
    expect(findCell({ fieldKey: 'ipAddress' }).text()).toBe(ipAddress);
    expect(findCell({ fieldKey: 'jobCount' }).text()).toBe('0');
    expect(findCell({ fieldKey: 'tagList' }).text()).toBe('');
    expect(findCell({ fieldKey: 'contactedAt' }).text()).toEqual(expect.any(String));

    // Actions
    const actions = findCell({ fieldKey: 'actions' });

    expect(actions.findComponent(RunnerEditButton).exists()).toBe(true);
    expect(actions.findByTestId('toggle-active-runner').exists()).toBe(true);
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

    expect(findCell({ fieldKey: 'summary' }).text()).toContain(`#${numericId} (${shortSha})`);
  });

  describe('When data is loading', () => {
    it('shows a busy state', () => {
      createComponent({ props: { runners: [], loading: true } });
      expect(findTable().attributes('busy')).toBeTruthy();
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
