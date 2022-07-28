import { shallowMount, mount } from '@vue/test-utils';
import { s__ } from '~/locale';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RunnerStatusStat from '~/runner/components/stat/runner_status_stat.vue';
import { INSTANCE_TYPE, STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '~/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findStatusStats = () => wrapper.findAllComponents(RunnerStatusStat).wrappers;

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
    expect(text).toMatch(`${s__('Runners|Online runners')} 3`);
    expect(text).toMatch(`${s__('Runners|Offline runners')} 2`);
    expect(text).toMatch(`${s__('Runners|Stale runners')} 1`);
  });

  it('Displays all counts for filtered searches', () => {
    const mockVariables = { paused: true };
    createComponent({ props: { variables: mockVariables } });

    findStatusStats().forEach((stat) => {
      expect(stat.props('variables')).toEqual(mockVariables);
    });
  });
});
