import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';

describe('HiddenBadge component', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(HiddenBadge, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        issuableType: 'issue',
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  beforeEach(() => {
    mountComponent();
  });

  it('renders warning badge', () => {
    expect(findBadge().attributes('aria-label')).toBe('Hidden');
    expect(findBadge().props('variant')).toEqual('warning');
  });

  it('renders spam icon', () => {
    expect(findBadge().props('icon')).toBe('spam');
  });

  it('has tooltip', () => {
    expect(getBinding(wrapper.element, 'gl-tooltip')).not.toBeUndefined();
  });

  it('has title', () => {
    expect(findBadge().attributes('title')).toBe(
      'This issue is hidden because its author has been banned.',
    );
  });
});
