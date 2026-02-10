import { shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import PolicyBadge from '~/projects/settings/repository/branch_rules/components/policy_badge.vue';

describe('PolicyBadge', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PolicyBadge, {
      propsData: props,
      provide: {
        securityPoliciesPath: '/security/policies',
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('when isProtectedByPolicy is true', () => {
    beforeEach(() => {
      createComponent({ isProtectedByPolicy: true });
    });

    it('renders default badge state', () => {
      expect(findBadge().props('variant')).toBe('info');
      expect(findBadge().props('icon')).toBe('shield');
      expect(findBadge().text()).toBe('Enforced by policy');
    });
  });

  describe('when isProtectedByPolicy is false', () => {
    beforeEach(() => {
      createComponent({ isProtectedByPolicy: false });
    });

    it('renders warn mode state', () => {
      expect(findBadge().props('variant')).toBe('neutral');
      expect(findBadge().props('icon')).toBe('shield');
      expect(findBadge().text()).toBe('Policy warn mode');
    });
  });

  describe('default props', () => {
    beforeEach(() => {
      createComponent();
    });

    it('defaults isProtectedByPolicy to false', () => {
      expect(findBadge().props('variant')).toBe('neutral');
      expect(findBadge().text()).toBe('Policy warn mode');
    });
  });
});
