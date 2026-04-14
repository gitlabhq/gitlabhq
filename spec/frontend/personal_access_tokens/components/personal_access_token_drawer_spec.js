import { GlButton, GlAttributeList } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import PersonalAccessTokenDrawer from '~/personal_access_tokens/components/personal_access_token_drawer.vue';
import PersonalAccessTokenGranularScopes from '~/personal_access_tokens/components/personal_access_token_granular_scopes.vue';
import PersonalAccessTokenLegacyScopes from '~/personal_access_tokens/components/personal_access_token_legacy_scopes.vue';
import PersonalAccessTokenStatusBadge from '~/personal_access_tokens/components/personal_access_token_status_badge.vue';
import { mockTokens, mockLegacyScopes } from '../mock_data';

describe('PersonalAccessTokenDrawer', () => {
  let wrapper;

  const mockToken = mockTokens[0];

  const createComponent = ({ token = mockToken, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(PersonalAccessTokenDrawer, {
      propsData: { token },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
      stubs: {
        MountingPortal: stubComponent(MountingPortal, { name: 'MountingPortal' }),
      },
    });
  };

  const findMountingPortal = () => wrapper.findComponent(MountingPortal);
  const findCloseButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findAttributeList = () => wrapper.findComponent(GlAttributeList);
  const findRotateButton = () => wrapper.findByTestId('rotate-token');
  const findRevokeButton = () => wrapper.findByTestId('revoke-token');
  const findDuplicateButton = () => wrapper.findByTestId('duplicate-token');
  const findStatusBadge = () => wrapper.findComponent(PersonalAccessTokenStatusBadge);

  const findTokenExpiry = () => wrapper.findByTestId('token-expiry');
  const findTokenLastUsed = () => wrapper.findByTestId('token-last-used');
  const findTokenCreatedOn = () => wrapper.findByTestId('token-created-on');

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findGranularScopes = () => wrapper.findComponent(PersonalAccessTokenGranularScopes);
  const findLegacyScopes = () => wrapper.findComponent(PersonalAccessTokenLegacyScopes);

  beforeEach(() => {
    createComponent();
  });

  it('renders into the mounting portal', () => {
    expect(findMountingPortal().attributes()).toMatchObject({
      'mount-to': '#contextual-panel-portal',
    });
  });

  it('is closed when token is null', () => {
    createComponent({ token: null });

    expect(findMountingPortal().exists()).toBe(false);
  });

  it('is open when token is provided', () => {
    expect(findMountingPortal().exists()).toBe(true);
  });

  it('emits a close event when the close button is clicked', () => {
    findCloseButton().vm.$emit('click');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  describe('title and basic info', () => {
    it('renders title with token name', () => {
      expect(wrapper.text()).toContain('Personal access token detail');
      expect(wrapper.text()).toContain('Token 1');
    });

    it('renders attribute list with token details', () => {
      expect(findAttributeList().props('items')).toEqual([
        {
          icon: 'token',
          label: 'Type',
          text: 'Fine-grained token',
        },
        {
          icon: 'text-description',
          label: 'Description',
          text: 'Test token 1',
        },
        { icon: 'expire', type: 'expiresAt', label: 'Expires', text: '' },
        { icon: 'history', type: 'lastUsedAt', label: 'Last used', text: '' },
        { icon: 'earth', type: 'ipUsage', label: 'IP Usage', text: '' },
      ]);
    });

    it('renders placeholder when description is missing', () => {
      createComponent({ token: { ...mockToken, description: null } });

      expect(findAttributeList().props('items')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            icon: 'text-description',
            label: 'Description',
            text: 'No description provided.',
          }),
        ]),
      );
    });

    it('renders the legacy token type', () => {
      createComponent({ token: { ...mockTokens[1] } });

      expect(findAttributeList().props('items')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            icon: 'token',
            label: 'Type',
            text: 'Legacy token',
          }),
        ]),
      );
    });
  });

  describe('dates', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('renders expiry date with tooltip', () => {
      expect(findTokenExpiry().text()).toBe('Dec 31, 2025');

      expect(getBinding(findTokenExpiry().element, 'gl-tooltip').value).toBe(
        'December 31, 2025 at 12:00:00 AM GMT',
      );
    });

    it('renders last used date with tooltip', () => {
      expect(findTokenLastUsed().text()).toBe('Nov 1, 2025');

      expect(getBinding(findTokenLastUsed().element, 'gl-tooltip').value).toBe(
        'November 1, 2025 at 10:00:00 AM GMT',
      );
    });

    it('renders created on date with tooltip', () => {
      expect(findTokenCreatedOn().text()).toBe('Created on Oct 1, 2025');

      expect(getBinding(findTokenCreatedOn().element, 'gl-tooltip').value).toBe(
        'October 1, 2025 at 10:00:00 AM GMT',
      );
    });
  });

  describe('IP usage', () => {
    it('renders the section if last used IPs exist', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain('IP Usage');
      expect(wrapper.text()).toContain('192.168.1.1');
      expect(wrapper.text()).toContain('192.168.0.0');
    });

    it('renders placeholder if IP usage is empty', () => {
      createComponent({ mountFn: mountExtended, token: { ...mockTokens[1] } });

      expect(wrapper.text()).toContain('No IP activity recorded yet.');
    });
  });

  describe('header actions', () => {
    it('shows rotate and revoke buttons when token is active', () => {
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
      findRevokeButton().vm.$emit('click');

      expect(wrapper.emitted('revoke')).toHaveLength(1);
      expect(wrapper.emitted('revoke')[0]).toEqual([mockToken]);
    });

    it('does not show action buttons when token is not active and not granular', () => {
      createComponent({
        token: { ...mockToken, active: false, granular: false, scopes: mockLegacyScopes },
        mountFn: mountExtended,
      });

      expect(findRotateButton().exists()).toBe(false);
      expect(findRevokeButton().exists()).toBe(false);
      expect(findDuplicateButton().exists()).toBe(false);
    });

    it('shows only duplicate button for revoked granular tokens', () => {
      createComponent({
        token: { ...mockToken, active: false, revoked: true },
        mountFn: mountExtended,
      });

      expect(findDuplicateButton().exists()).toBe(true);
      expect(findRotateButton().exists()).toBe(false);
      expect(findRevokeButton().exists()).toBe(false);
    });

    it('shows duplicate button for active granular tokens', () => {
      createComponent({ mountFn: mountExtended });

      expect(findDuplicateButton().exists()).toBe(true);
    });

    it('does not show duplicate button for non-granular tokens', () => {
      createComponent({
        token: { ...mockToken, granular: false, scopes: mockLegacyScopes },
        mountFn: mountExtended,
      });

      expect(findDuplicateButton().exists()).toBe(false);
    });

    it('emits `duplicate` event when duplicate is clicked', () => {
      createComponent({ mountFn: mountExtended });

      findDuplicateButton().vm.$emit('click');

      expect(wrapper.emitted('duplicate')).toHaveLength(1);
      expect(wrapper.emitted('duplicate')[0]).toEqual([mockToken]);
    });
  });

  describe('status', () => {
    it('renders status badge', () => {
      expect(findStatusBadge().exists()).toBe(true);
      expect(findStatusBadge().props('token')).toEqual(mockToken);
    });
  });

  describe('scopes', () => {
    it('renders crud component', () => {
      createComponent({ mountFn: mountExtended });

      expect(findCrudComponent().exists()).toBe(true);
      expect(findCrudComponent().text()).toContain('Scopes');
    });

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
});
