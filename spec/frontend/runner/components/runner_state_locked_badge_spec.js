import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerStateLockedBadge from '~/runner/components/runner_state_locked_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerStateLockedBadge, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders locked state', () => {
    expect(wrapper.text()).toBe('locked');
    expect(findBadge().props('variant')).toBe('warning');
  });

  it('renders tooltip', () => {
    expect(getTooltip().value).toBeDefined();
  });

  it('passes arbitrary attributes to the badge', () => {
    createComponent({ props: { size: 'sm' } });

    expect(findBadge().props('size')).toBe('sm');
  });
});
