import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount, mount } from '@vue/test-utils';
import RunnerOnlineBadge from '~/runner/components/stat/runner_online_stat.vue';

describe('RunnerOnlineBadge', () => {
  let wrapper;

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);

  const createComponent = ({ props = {} } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(RunnerOnlineBadge, {
      propsData: {
        value: '99',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Uses a success appearance', () => {
    createComponent({}, shallowMount);

    expect(findSingleStat().props('variant')).toBe('success');
  });

  it('Renders a value', () => {
    createComponent({}, mount);

    expect(wrapper.text()).toMatch(new RegExp(`Online Runners 99\\s+online`));
  });
});
