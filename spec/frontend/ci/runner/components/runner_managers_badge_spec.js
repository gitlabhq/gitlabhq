import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerManagersBadge from '~/ci/runner/components/runner_managers_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

const mockCount = 2;

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltip = () => getBinding(findBadge()?.element, 'gl-tooltip');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerManagersBadge, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  it.each([null, 0, 1])('renders no badge when count is %s', (count) => {
    createComponent({ props: { count } });

    expect(findBadge().exists()).toBe(false);
  });

  it('renders badge with tooltip', () => {
    createComponent({ props: { count: mockCount } });

    expect(findBadge().text()).toBe(`${mockCount}`);
    expect(getTooltip().value).toContain(`${mockCount}`);
  });

  it('renders badge with icon and variant', () => {
    createComponent({ props: { count: mockCount } });

    expect(findBadge().props('icon')).toBe('container-image');
    expect(findBadge().props('variant')).toBe('muted');
  });

  it('renders badge and tooltip with formatted count', () => {
    createComponent({ props: { count: 1000 } });

    expect(findBadge().text()).toBe('1,000');
    expect(getTooltip().value).toContain('1,000');
  });
});
