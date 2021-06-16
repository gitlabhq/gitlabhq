import { GlLink, GlTable, GlSkeletonLoader } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerList from '~/runner/components/runner_list.vue';
import { runnersData } from '../mock_data';

const mockRunners = runnersData.data.runners.nodes;
const mockActiveRunnersCount = mockRunners.length;

describe('RunnerList', () => {
  let wrapper;

  const findActiveRunnersMessage = () => wrapper.findByTestId('active-runners-message');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => wrapper.findAll('th');
  const findRows = () => wrapper.findAll('[data-testid^="runner-row-"]');
  const findCell = ({ row = 0, fieldKey }) =>
    extendedWrapper(findRows().at(row).find(`[data-testid="td-${fieldKey}"]`));

  const createComponent = ({ props = {} } = {}, mountFn = shallowMount) => {
    wrapper = extendedWrapper(
      mountFn(RunnerList, {
        propsData: {
          runners: mockRunners,
          activeRunnersCount: mockActiveRunnersCount,
          ...props,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent({}, mount);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays active runner count', () => {
    expect(findActiveRunnersMessage().text()).toBe(
      `Runners currently online: ${mockActiveRunnersCount}`,
    );
  });

  it('Displays a large active runner count', () => {
    createComponent({ props: { activeRunnersCount: 2000 } });

    expect(findActiveRunnersMessage().text()).toBe('Runners currently online: 2,000');
  });

  it('Displays headers', () => {
    const headerLabels = findHeaders().wrappers.map((w) => w.text());

    expect(headerLabels).toEqual([
      'Type/State',
      'Runner',
      'Version',
      'IP Address',
      'Projects',
      'Jobs',
      'Tags',
      'Last contact',
      '', // actions has no label
    ]);
  });

  it('Displays a list of runners', () => {
    expect(findRows()).toHaveLength(3);

    expect(findSkeletonLoader().exists()).toBe(false);
  });

  it('Displays details of a runner', () => {
    const { id, description, version, ipAddress, shortSha } = mockRunners[0];

    // Badges
    expect(findCell({ fieldKey: 'type' }).text()).toMatchInterpolatedText('specific paused');

    // Runner identifier
    expect(findCell({ fieldKey: 'name' }).text()).toContain(
      `#${getIdFromGraphQLId(id)} (${shortSha})`,
    );
    expect(findCell({ fieldKey: 'name' }).text()).toContain(description);

    // Other fields: some cells are empty in the first iteration
    // See https://gitlab.com/gitlab-org/gitlab/-/issues/329658#pending-features
    expect(findCell({ fieldKey: 'version' }).text()).toBe(version);
    expect(findCell({ fieldKey: 'ipAddress' }).text()).toBe(ipAddress);
    expect(findCell({ fieldKey: 'projectCount' }).text()).toBe('');
    expect(findCell({ fieldKey: 'jobCount' }).text()).toBe('');
    expect(findCell({ fieldKey: 'tagList' }).text()).toBe('');
    expect(findCell({ fieldKey: 'contactedAt' }).text()).toEqual(expect.any(String));

    // Actions
    const actions = findCell({ fieldKey: 'actions' });

    expect(actions.findByTestId('edit-runner').exists()).toBe(true);
    expect(actions.findByTestId('toggle-active-runner').exists()).toBe(true);
  });

  it('Links to the runner page', () => {
    const { id } = mockRunners[0];

    expect(findCell({ fieldKey: 'name' }).find(GlLink).attributes('href')).toBe(
      `/admin/runners/${getIdFromGraphQLId(id)}`,
    );
  });

  describe('When data is loading', () => {
    it('shows a busy state', () => {
      createComponent({ props: { runners: [], loading: true } });
      expect(findTable().attributes('busy')).toBeTruthy();
    });

    it('when there are no runners, shows an skeleton loader', () => {
      createComponent({ props: { runners: [], loading: true } }, mount);

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('when there are runners, shows a busy indicator skeleton loader', () => {
      createComponent({ props: { loading: true } }, mount);

      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
