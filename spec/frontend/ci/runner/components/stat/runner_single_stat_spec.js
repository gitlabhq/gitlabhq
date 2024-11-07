import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import RunnerSingleStat from '~/ci/runner/components/stat/runner_single_stat.vue';
import RunnerCount from '~/ci/runner/components/stat/runner_count.vue';
import { INSTANCE_TYPE, GROUP_TYPE } from '~/ci/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerCount = () => wrapper.findComponent(RunnerCount);
  const findGlSingleStat = () => wrapper.findComponent(GlSingleStat);

  const createComponent = ({ props = {}, count, mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(RunnerSingleStat, {
      propsData: {
        scope: INSTANCE_TYPE,
        title: 'My title',
        variables: {},
        ...props,
      },
      stubs: {
        RunnerCount: {
          ...RunnerCount,
          data() {
            return {
              count,
            };
          },
        },
      },
      ...options,
    });
  };

  it.each`
    case              | count   | value
    ${'number'}       | ${99}   | ${'99'}
    ${'long number'}  | ${1000} | ${'1,000'}
    ${'empty number'} | ${null} | ${'-'}
  `('formats $case', ({ count, value }) => {
    createComponent({ count });

    expect(findGlSingleStat().props('value')).toBe(value);
  });

  it('Passes runner count props', () => {
    const props = {
      scope: GROUP_TYPE,
      variables: { paused: true },
      skip: true,
    };

    createComponent({ props });

    expect(findRunnerCount().props()).toEqual(props);
  });
});
