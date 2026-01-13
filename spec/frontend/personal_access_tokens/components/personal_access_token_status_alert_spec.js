import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenStatusAlert from '~/personal_access_tokens/components/personal_access_token_status_alert.vue';

describe('PersonalAccessTokenStatusAlert', () => {
  let wrapper;

  const createComponent = (token = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenStatusAlert, {
      propsData: {
        token: {
          active: true,
          revoked: false,
          expiresAt: null,
          ...token,
        },
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('when token is revoked', () => {
    beforeEach(() => {
      createComponent({ revoked: true, active: false });
    });

    it('displays revoked alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes('variant')).toBe('info');
      expect(findAlert().text()).toBe('This token was revoked.');
    });
  });

  describe('when token is expired', () => {
    beforeEach(() => {
      createComponent({ active: false, revoked: false });
    });

    it('displays expired alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes('variant')).toBe('info');
      expect(findAlert().text()).toBe('This token has expired.');
    });
  });

  describe('when token is expiring soon', () => {
    beforeEach(() => {
      jest.useFakeTimers({ legacyFakeTimers: false });
      jest.setSystemTime(new Date('2025-11-24'));

      createComponent({ active: true, expiresAt: '2025-12-01' });
    });

    it('displays expiring soon alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes('variant')).toBe('warning');
      expect(findAlert().text()).toBe(
        'This token expires soon. If still needed, generate a new token with the same settings.',
      );
    });
  });

  describe('when token is active and not expiring soon', () => {
    beforeEach(() => {
      jest.useFakeTimers({ legacyFakeTimers: false });
      jest.setSystemTime(new Date('2025-11-01'));

      // Token expires in 30 days (not within 2 weeks)
      createComponent({ active: true, expiresAt: '2025-12-01' });
    });

    it('does not display any alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when token has no expiry date', () => {
    beforeEach(() => {
      createComponent({ active: true, expiresAt: null });
    });

    it('does not display any alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });
});
