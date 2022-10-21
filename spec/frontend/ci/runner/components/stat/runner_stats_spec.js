import { shallowMount, mount } from '@vue/test-utils';
import RunnerStats from '~/ci/runner/components/stat/runner_stats.vue';
import RunnerSingleStat from '~/ci/runner/components/stat/runner_single_stat.vue';
import {
  I18N_STATUS_ONLINE,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  INSTANCE_TYPE,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_STALE,
} from '~/ci/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findSingleStats = () => wrapper.findAllComponents(RunnerSingleStat);

  const createComponent = ({ props = {}, mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(RunnerStats, {
      propsData: {
        scope: INSTANCE_TYPE,
        variables: {},
        ...props,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays all the stats', () => {
    const mockCounts = {
      [STATUS_ONLINE]: 3,
      [STATUS_OFFLINE]: 2,
      [STATUS_STALE]: 1,
    };

    createComponent({
      mountFn: mount,
      stubs: {
        RunnerCount: {
          props: ['variables'],
          render() {
            return this.$scopedSlots.default({
              count: mockCounts[this.variables.status],
            });
          },
        },
      },
    });

    const text = wrapper.text();
    expect(text).toContain(`${I18N_STATUS_ONLINE} 3`);
    expect(text).toContain(`${I18N_STATUS_OFFLINE} 2`);
    expect(text).toContain(`${I18N_STATUS_STALE} 1`);
  });

  it('Skips query for other stats', () => {
    createComponent({
      props: {
        variables: { status: STATUS_ONLINE },
      },
    });

    expect(findSingleStats().at(0).props('skip')).toBe(false);
    expect(findSingleStats().at(1).props('skip')).toBe(true);
    expect(findSingleStats().at(2).props('skip')).toBe(true);
  });

  it('Displays all counts for filtered searches', () => {
    const mockVariables = { paused: true };
    createComponent({ props: { variables: mockVariables } });

    findSingleStats().wrappers.forEach((stat) => {
      expect(stat.props('variables')).toMatchObject(mockVariables);
    });
  });
});
