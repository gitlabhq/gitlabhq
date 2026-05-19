import { GlAttributeList } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import DynamicPanel from '~/vue_shared/components/dynamic_panel.vue';
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

  const createComponent = ({
    token = mockToken,
    mountFn = shallowMountExtended,
    provide = {},
  } = {}) => {
    wrapper = mountFn(PersonalAccessTokenDrawer, {
      propsData: {
        token,
      },
      provide: {
        granularTokensEnforced: false,
        ...provide,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        DynamicPanel,
        MountingPortal: stubComponent(MountingPortal, { name: 'MountingPortal' }),
      },
    });
  };

  const findMountingPortal = () => wrapper.findComponent(MountingPortal);
  const findDynamicPanel = () => wrapper.findComponent(DynamicPanel);
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

  it('emits a close event when dynamic panel emits a close event', () => {
    findDynamicPanel().vm.$emit('close');

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
    describe('when the token is granular', () => {
      describe('when the token is active', () => {
        it('shows rotate, revoke and duplicate actions', () => {
          expect(findRotateButton().exists()).toBe(true);

          expect(findRevokeButton().exists()).toBe(true);
          expect(findRevokeButton().props('variant')).toBe('danger');

          expect(findDuplicateButton().exists()).toBe(true);
        });
      });

      describe('when the token is inactive', () => {
        it('does not show rotate or revoke, but shows duplicate action', () => {
          createComponent({
            token: { ...mockToken, granular: true, active: false },
            mountFn: mountExtended,
          });

          expect(findRotateButton().exists()).toBe(false);
          expect(findRevokeButton().exists()).toBe(false);
          expect(findDuplicateButton().exists()).toBe(true);
        });
      });
    });

    describe('when the token is not granular', () => {
      describe('when the token is active', () => {
        it('shows rotate and revoke actions only', () => {
          createComponent({
            token: { ...mockToken, granular: false, active: true, scopes: mockLegacyScopes },
            mountFn: mountExtended,
          });

          expect(findRotateButton().exists()).toBe(true);

          expect(findRevokeButton().exists()).toBe(true);
          expect(findRevokeButton().props('variant')).toBe('danger');

          expect(findDuplicateButton().exists()).toBe(false);
        });
      });

      describe('when the token is inactive', () => {
        it('does not show any actions', () => {
          createComponent({
            token: { ...mockToken, granular: false, active: false, scopes: mockLegacyScopes },
            mountFn: mountExtended,
          });

          expect(findRotateButton().exists()).toBe(false);
          expect(findRevokeButton().exists()).toBe(false);
          expect(findDuplicateButton().exists()).toBe(false);
        });
      });
    });

    describe('when granular tokens are enforced', () => {
      describe('when the token is granular and active', () => {
        it('shows rotate button', () => {
          createComponent({
            token: { ...mockToken, granular: true, active: true },
            mountFn: mountExtended,
            provide: { granularTokensEnforced: true },
          });

          expect(findRotateButton().exists()).toBe(true);
          expect(findRevokeButton().exists()).toBe(true);
        });
      });

      describe('when the token is not granular and active', () => {
        it('does not show rotate button', () => {
          createComponent({
            token: { ...mockToken, granular: false, active: true, scopes: mockLegacyScopes },
            mountFn: mountExtended,
            provide: { granularTokensEnforced: true },
          });

          expect(findRotateButton().exists()).toBe(false);
          expect(findRevokeButton().exists()).toBe(true);
        });
      });
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
