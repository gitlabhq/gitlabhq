import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LockedBadge from '~/issuable/components/locked_badge.vue';

describe('LockedBadge component', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(LockedBadge, {
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
    expect(findBadge().attributes('aria-label')).toBe(
      'The discussion in this issue is locked. Only project members can comment.',
    );
    expect(findBadge().props('variant')).toEqual('warning');
  });

  it('renders lock icon', () => {
    expect(findBadge().props('icon')).toBe('lock');
  });

  it('has tooltip', () => {
    expect(getBinding(wrapper.element, 'gl-tooltip')).not.toBeUndefined();
  });

  it('has title', () => {
    expect(findBadge().attributes('title')).toBe(
      'The discussion in this issue is locked. Only project members can comment.',
    );
  });
});
