import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import PersonalAccessTokenDrawer from '~/personal_access_tokens/components/personal_access_token_drawer.vue';
import PersonalAccessTokenGranularScopes from '~/personal_access_tokens/components/personal_access_token_granular_scopes.vue';
import PersonalAccessTokenLegacyScopes from '~/personal_access_tokens/components/personal_access_token_legacy_scopes.vue';
import PersonalAccessTokenStatusAlert from '~/personal_access_tokens/components/personal_access_token_status_alert.vue';
import PersonalAccessTokenStatusBadge from '~/personal_access_tokens/components/personal_access_token_status_badge.vue';
import { mockTokens } from '../mock_data';

describe('PersonalAccessTokenDrawer', () => {
  let wrapper;

  const mockToken = mockTokens[0];

  const createComponent = ({ token = mockToken, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(PersonalAccessTokenDrawer, {
      propsData: { token },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findRotateButton = () => wrapper.findByTestId('rotate-token');
  const findRevokeButton = () => wrapper.findByTestId('revoke-token');
  const findStatusAlert = () => wrapper.findComponent(PersonalAccessTokenStatusAlert);
  const findStatusBadge = () => wrapper.findComponent(PersonalAccessTokenStatusBadge);

  const findGranularScopes = () => wrapper.findComponent(PersonalAccessTokenGranularScopes);
  const findLegacyScopes = () => wrapper.findComponent(PersonalAccessTokenLegacyScopes);

  it('is closed when token is null', () => {
    createComponent({ token: null });

    expect(findDrawer().props('open')).toBe(false);
  });

  it('is open when token is provided', () => {
    createComponent();

    expect(findDrawer().props('open')).toBe(true);
  });

  it('emits close when drawer emits close', () => {
    createComponent();

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  describe('title and basic info', () => {
    it('renders title with token name', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain("Details for 'Token 1'");
    });

    it('renders token description', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain(mockToken.description);
    });

    it('renders placeholder when description is missing', () => {
      createComponent({
        mountFn: mountExtended,
        token: { ...mockToken, description: null },
      });

      expect(wrapper.text()).toContain('No description provided.');
    });
  });

  describe('header actions', () => {
    it('shows rotate and revoke buttons when token is active', () => {
      createComponent({ mountFn: mountExtended });

      expect(findRotateButton().exists()).toBe(true);
      expect(findRevokeButton().exists()).toBe(true);
      expect(findRevokeButton().props('variant')).toBe('danger');
    });

    it('emits `rotate` event when rotate is clicked', () => {
      createComponent({ mountFn: mountExtended });

      findRotateButton().vm.$emit('click');

      expect(wrapper.emitted('rotate')).toHaveLength(1);
      expect(wrapper.emitted('rotate')[0]).toEqual([mockToken]);
    });

    it('emits `revoke` event when revoke is clicked', () => {
      createComponent({ mountFn: mountExtended });

      findRevokeButton().vm.$emit('click');

      expect(wrapper.emitted('revoke')).toHaveLength(1);
      expect(wrapper.emitted('revoke')[0]).toEqual([mockToken]);
    });

    it('does not show action buttons when token is not active', () => {
      createComponent({
        token: { ...mockToken, active: false },
        mountFn: mountExtended,
      });

      expect(findRotateButton().exists()).toBe(false);
      expect(findRevokeButton().exists()).toBe(false);
    });
  });

  describe('status', () => {
    it('renders status alert', () => {
      createComponent({ mountFn: mountExtended });

      expect(findStatusAlert().exists()).toBe(true);
      expect(findStatusBadge().props('token')).toEqual(mockToken);
    });

    it('renders status badge', () => {
      createComponent();

      expect(findStatusBadge().exists()).toBe(true);
      expect(findStatusBadge().props('token')).toEqual(mockToken);
    });
  });

  describe('dates', () => {
    it('renders expiry date', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain('Expires');
      expect(wrapper.text()).toContain('Dec 31, 2025');
    });

    it('renders last used date', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain('Last used');
      expect(wrapper.text()).toContain('Nov 1, 2025');
    });
  });

  describe('IP usage', () => {
    it('renders the section if last used IPs exist', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain('IP Usage');
      expect(wrapper.text()).toContain('192.168.1.1');
      expect(wrapper.text()).toContain('192.168.0.0');
    });

    it('does not render the section if last used IPs are empty', () => {
      createComponent({ mountFn: mountExtended, token: { ...mockTokens[1] } });

      expect(wrapper.text()).not.toContain('IP Usage');
    });
  });

  describe('scopes', () => {
    it('renders granular scopes component when token is granular', () => {
      createComponent({ token: { ...mockToken, granular: true } });

      expect(findGranularScopes().exists()).toBe(true);
      expect(findGranularScopes().props('scopes')).toEqual(mockToken.scopes);

      expect(findLegacyScopes().exists()).toBe(false);
    });

    it('renders legacy scopes component when token is not granular', () => {
      createComponent({ token: { ...mockToken, granular: false } });

      expect(findLegacyScopes().exists()).toBe(true);
      expect(findLegacyScopes().props('scopes')).toEqual(mockToken.scopes);

      expect(findGranularScopes().exists()).toBe(false);
    });
  });

  describe('metadata', () => {
    it('renders created timestamp', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain('Created');
      expect(wrapper.text()).toContain('October 1, 2025 at 10:00:00 AM GMT');
    });

    it('shows fine-grained token label when granular', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain('Fine-grained token');
    });

    it('shows legacy token label when not granular', () => {
      createComponent({ mountFn: mountExtended, token: { ...mockTokens[1] } });

      expect(wrapper.text()).toContain('Legacy token');
    });
  });
});
