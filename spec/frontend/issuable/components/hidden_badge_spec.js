import { GlBadge, GlIcon } from '@gitlab/ui';
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
  const findIcon = () => wrapper.findComponent(GlIcon);

  beforeEach(() => {
    mountComponent();
  });

  it('renders warning badge', () => {
    expect(findBadge().text()).toBe('Hidden');
    expect(findBadge().props('variant')).toEqual('warning');
  });

  it('renders spam icon', () => {
    expect(findIcon().props('name')).toBe('spam');
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
