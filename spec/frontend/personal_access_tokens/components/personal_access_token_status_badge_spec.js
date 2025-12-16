import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import PersonalAccessTokenStatusBadge from '~/personal_access_tokens/components/personal_access_token_status_badge.vue';

describe('PersonalAccessTokenStatusBadge', () => {
  let wrapper;

  const createComponent = (token = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenStatusBadge, {
      propsData: {
        token: {
          active: true,
          revoked: false,
          expiresAt: null,
          ...token,
        },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('when token is revoked', () => {
    beforeEach(() => {
      createComponent({ revoked: true, active: false });
    });

    it('displays revoked badge', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().text()).toBe('Revoked');
      expect(findBadge().props()).toMatchObject({
        icon: 'remove',
        variant: 'danger',
      });
    });
  });

  describe('when token is expired', () => {
    beforeEach(() => {
      createComponent({ active: false, revoked: false });
    });

    it('displays expired badge', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().text()).toBe('Expired');
      expect(findBadge().props()).toMatchObject({
        icon: 'time-out',
      });
    });
  });

  describe('when token is expiring soon', () => {
    beforeEach(() => {
      jest.useFakeTimers({ legacyFakeTimers: false });
      jest.setSystemTime(new Date('2025-11-24'));

      createComponent({ active: true, expiresAt: '2025-12-01' });
    });

    it('displays expiring soon badge', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().text()).toBe('Expiring soon');
      expect(findBadge().props()).toMatchObject({
        icon: 'expire',
        variant: 'warning',
      });
    });

    it('has tooltip with explanation', () => {
      const tooltip = getBinding(findBadge().element, 'gl-tooltip');
      expect(tooltip.value).toBe('Token expires in less than two weeks.');
    });
  });

  describe('when token is active and not expiring soon', () => {
    beforeEach(() => {
      jest.useFakeTimers({ legacyFakeTimers: false });
      jest.setSystemTime(new Date('2025-11-01'));

      // Token expires in 30 days (not within 2 weeks)
      createComponent({ active: true, expiresAt: '2025-12-01' });
    });

    it('does not display any badge', () => {
      expect(findBadge().exists()).toBe(false);
    });
  });

  describe('when token has no expiry date', () => {
    beforeEach(() => {
      createComponent({ active: true, expiresAt: null });
    });

    it('does not display any badge', () => {
      expect(findBadge().exists()).toBe(false);
    });
  });
});
