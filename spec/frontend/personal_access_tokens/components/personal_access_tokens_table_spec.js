import {
  GlTable,
  GlLoadingIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButton,
} from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import PersonalAccessTokensTable from '~/personal_access_tokens/components/personal_access_tokens_table.vue';
import PersonalAccessTokenStatusBadge from '~/personal_access_tokens/components/personal_access_token_status_badge.vue';
import { mockTokens } from '../mock_data';

describe('PersonalAccessTokensTable', () => {
  let wrapper;

  const createComponent = ({
    tokens = mockTokens,
    loading = false,
    mountFn = shallowMountExtended,
    provide = {},
  } = {}) => {
    wrapper = mountFn(PersonalAccessTokensTable, {
      propsData: {
        tokens,
        loading,
      },
      provide: {
        granularTokensEnforced: false,
        ...provide,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusBadges = () => findTable().findAllComponents(PersonalAccessTokenStatusBadge);
  const findActionDropdowns = () => findTable().findAllComponents(GlDisclosureDropdown);

  const findActionItems = (idx) =>
    findActionDropdowns().at(idx).findAllComponents(GlDisclosureDropdownItem);

  const findTokenNameLinks = () =>
    findTable()
      .findAllComponents(GlButton)
      .filter((button) => button.props('variant') === 'link');

  const findTokenExpiryDates = () => wrapper.findAllByTestId('token-expiry');
  const findTokenLastUsedDates = () => wrapper.findAllByTestId('token-last-used');

  beforeEach(() => {
    createComponent();
  });

  it('renders a table', () => {
    expect(findTable().exists()).toBe(true);
  });

  it('passes tokens to the table', () => {
    expect(findTable().props('items')).toEqual(mockTokens);
  });

  describe('loading state', () => {
    it('shows loading icon when loading', () => {
      createComponent({ loading: true });

      expect(findTable().attributes('busy')).toBe('true');
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('hides loading icon when not loading', () => {
      createComponent({ loading: false });

      expect(findTable().attributes('busy')).toBeUndefined();
    });
  });

  describe('empty state', () => {
    it('shows empty message when no tokens', () => {
      createComponent({ tokens: [], loading: false, mountFn: mountExtended });

      expect(findTable().text()).toContain('No access tokens');
    });
  });

  describe('token name column', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('renders token names as clickable buttons', () => {
      expect(findTokenNameLinks()).toHaveLength(2);
      expect(findTokenNameLinks().at(0).text()).toBe('Token 1');
      expect(findTokenNameLinks().at(1).text()).toBe('Token 2');
    });

    it('emits `select` event when token name is clicked', () => {
      findTokenNameLinks().at(0).vm.$emit('click');

      expect(wrapper.emitted('select')).toHaveLength(1);
      expect(wrapper.emitted('select')[0]).toEqual([mockTokens[0]]);
    });
  });

  describe('description column', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('displays token description when present', () => {
      expect(findTable().text()).toContain('Test token 1');
    });

    it('displays placeholder when description is missing', () => {
      expect(findTable().text()).toContain('No description provided.');
    });
  });

  describe('status column', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('renders status badges for each token', () => {
      expect(findStatusBadges()).toHaveLength(2);
    });

    it('passes token to status badge', () => {
      expect(findStatusBadges().at(0).props('token')).toEqual(mockTokens[0]);
    });

    it('displays expiry date', () => {
      expect(findTokenExpiryDates()).toHaveLength(2);
      expect(findTokenExpiryDates().at(0).text()).toBe('Expires: Dec 31, 2025');
      expect(findTokenExpiryDates().at(1).text()).toBe('Expires: Never');
    });

    it('displays expiry date tooltip', () => {
      expect(getBinding(findTokenExpiryDates().at(0).element, 'gl-tooltip').value).toBe(
        'December 31, 2025 at 12:00:00 AM GMT',
      );
      expect(getBinding(findTokenExpiryDates().at(1).element, 'gl-tooltip').value).toBe('Never');
    });

    it('displays last used date', () => {
      expect(findTokenLastUsedDates()).toHaveLength(2);
      expect(findTokenLastUsedDates().at(0).text()).toBe('Last used: Nov 1, 2025');
      expect(findTokenLastUsedDates().at(1).text()).toBe('Last used: Never');
    });

    it('displays last used date tooltip', () => {
      expect(getBinding(findTokenLastUsedDates().at(0).element, 'gl-tooltip').value).toBe(
        'November 1, 2025 at 10:00:00 AM GMT',
      );
      expect(getBinding(findTokenLastUsedDates().at(1).element, 'gl-tooltip').value).toBe('Never');
    });
  });

  describe('actions column', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('shows action dropdown', () => {
      expect(findActionDropdowns()).toHaveLength(2);
    });

    it('configures dropdown with correct props', () => {
      expect(findActionDropdowns().at(0).props()).toMatchObject({
        category: 'tertiary',
        icon: 'ellipsis_v',
        noCaret: true,
        placement: 'bottom-end',
        toggleText: 'Actions',
        textSrOnly: true,
      });
    });

    describe('action items', () => {
      const activeGranularToken = { ...mockTokens[0], granular: true, active: true };
      const inactiveNonGranularToken = { ...mockTokens[1], granular: false, active: false };

      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          tokens: [activeGranularToken, inactiveNonGranularToken],
        });
      });

      describe('when the token is granular', () => {
        describe('when the token is active', () => {
          it('shows view details, duplicate, rotate and revoke actions', () => {
            createComponent({
              mountFn: mountExtended,
              tokens: [{ ...mockTokens[0], granular: true, active: true }],
            });

            expect(findActionItems(0)).toHaveLength(4);
            expect(findActionItems(0).at(0).text()).toBe('View details');
            expect(findActionItems(0).at(1).text()).toBe('Duplicate');
            expect(findActionItems(0).at(2).text()).toBe('Rotate');
            expect(findActionItems(0).at(3).text()).toBe('Revoke');
            expect(findActionItems(0).at(3).props('variant')).toBe('danger');
          });
        });

        describe('when the token is inactive', () => {
          it('shows view details, duplicate actions', () => {
            createComponent({
              mountFn: mountExtended,
              tokens: [{ ...mockTokens[0], granular: true, active: false }],
            });

            expect(findActionItems(0)).toHaveLength(2);
            expect(findActionItems(0).at(0).text()).toBe('View details');
            expect(findActionItems(0).at(1).text()).toBe('Duplicate');
          });
        });
      });

      describe('when the token is not granular', () => {
        describe('when the token is active', () => {
          it('shows view details, rotate and revoke actions', () => {
            createComponent({
              mountFn: mountExtended,
              tokens: [{ ...mockTokens[1], granular: false, active: true }],
            });

            expect(findActionItems(0)).toHaveLength(3);
            expect(findActionItems(0).at(0).text()).toBe('View details');
            expect(findActionItems(0).at(1).text()).toBe('Rotate');
            expect(findActionItems(0).at(2).text()).toBe('Revoke');
            expect(findActionItems(0).at(2).props('variant')).toBe('danger');
          });
        });

        describe('when the token is inactive', () => {
          it('shows view details action', () => {
            createComponent({
              mountFn: mountExtended,
              tokens: [{ ...mockTokens[1], granular: false, active: false }],
            });

            expect(findActionItems(0)).toHaveLength(1);
            expect(findActionItems(0).at(0).text()).toBe('View details');
          });
        });
      });

      describe('when granular tokens are enforced', () => {
        describe('when the token is granular and active', () => {
          it('shows rotate button', () => {
            createComponent({
              mountFn: mountExtended,
              tokens: [{ ...mockTokens[0], granular: true, active: true }],
              provide: { granularTokensEnforced: true },
            });

            expect(findActionItems(0)).toHaveLength(4);
            expect(findActionItems(0).at(0).text()).toBe('View details');
            expect(findActionItems(0).at(1).text()).toBe('Duplicate');
            expect(findActionItems(0).at(2).text()).toBe('Rotate');
            expect(findActionItems(0).at(3).text()).toBe('Revoke');
          });
        });

        describe('when the token is not granular and active', () => {
          it('does not show rotate button', () => {
            createComponent({
              mountFn: mountExtended,
              tokens: [{ ...mockTokens[1], granular: false, active: true }],
              provide: { granularTokensEnforced: true },
            });

            expect(findActionItems(0)).toHaveLength(2);
            expect(findActionItems(0).at(0).text()).toBe('View details');
            expect(findActionItems(0).at(1).text()).toBe('Revoke');
          });
        });
      });

      it('emits `select` event when view details is clicked', () => {
        findActionItems(0).at(0).vm.$emit('action');

        expect(wrapper.emitted('select')).toHaveLength(1);
        expect(wrapper.emitted('select')[0]).toEqual([mockTokens[0]]);
      });

      it('emits `duplicate` event when duplicate is clicked', () => {
        findActionItems(0).at(1).vm.$emit('action');

        expect(wrapper.emitted('duplicate')).toHaveLength(1);
        expect(wrapper.emitted('duplicate')[0]).toEqual([mockTokens[0]]);
      });

      it('emits `rotate` event when rotate is clicked', () => {
        findActionItems(0).at(2).vm.$emit('action');

        expect(wrapper.emitted('rotate')).toHaveLength(1);
        expect(wrapper.emitted('rotate')[0]).toEqual([mockTokens[0]]);
      });

      it('emits `revoke` event when revoke is clicked', () => {
        findActionItems(0).at(3).vm.$emit('action');

        expect(wrapper.emitted('revoke')).toHaveLength(1);
        expect(wrapper.emitted('revoke')[0]).toEqual([mockTokens[0]]);
      });
    });
  });
});
