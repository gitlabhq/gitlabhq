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
  } = {}) => {
    wrapper = mountFn(PersonalAccessTokensTable, {
      propsData: {
        tokens,
        loading,
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

    it('does not show rotate & revoke for inactive tokens', () => {
      expect(findActionItems(0)).toHaveLength(3);
      expect(findActionItems(1)).toHaveLength(1);
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
      it('includes view details action', () => {
        expect(findActionItems(0).at(0).text()).toBe('View details');
        expect(findActionItems(1).at(0).text()).toBe('View details');
      });

      it('includes rotate action', () => {
        expect(findActionItems(0).at(1).text()).toBe('Rotate');
      });

      it('includes revoke action', () => {
        expect(findActionItems(0).at(2).text()).toBe('Revoke');
        expect(findActionItems(0).at(2).props('variant')).toBe('danger');
      });

      it('emits `select` event when view details is clicked', () => {
        findActionItems(0).at(0).vm.$emit('action');

        expect(wrapper.emitted('select')).toHaveLength(1);
        expect(wrapper.emitted('select')[0]).toEqual([mockTokens[0]]);
      });

      it('emits `rotate` event when rotate is clicked', () => {
        findActionItems(0).at(1).vm.$emit('action');

        expect(wrapper.emitted('rotate')).toHaveLength(1);
        expect(wrapper.emitted('rotate')[0]).toEqual([mockTokens[0]]);
      });

      it('emits `revoke` event when revoke is clicked', () => {
        findActionItems(0).at(2).vm.$emit('action');

        expect(wrapper.emitted('revoke')).toHaveLength(1);
        expect(wrapper.emitted('revoke')[0]).toEqual([mockTokens[0]]);
      });
    });
  });
});
