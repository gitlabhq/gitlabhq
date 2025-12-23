import { GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenLegacyScopes from '~/personal_access_tokens/components/personal_access_token_legacy_scopes.vue';
import { mockLegacyScopes } from '../mock_data';

describe('PersonalAccessTokenLegacyScopes', () => {
  let wrapper;

  const createComponent = ({ scopes = mockLegacyScopes } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenLegacyScopes, {
      propsData: { scopes },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findIcons = () => wrapper.findAllComponents(GlIcon);

  beforeEach(() => {
    createComponent();
  });

  describe('header and warning', () => {
    it('shows scope header', () => {
      expect(wrapper.text()).toContain('Token scope');
    });

    it('shows warning badge with correct props', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().props()).toMatchObject({
        icon: 'error',
        variant: 'warning',
      });
      expect(findBadge().text()).toBe('Consider reducing scope');
    });
  });

  describe('scope rendering', () => {
    it('shows check icon', () => {
      expect(findIcons().at(0).props()).toMatchObject({
        name: 'check-sm',
        variant: 'success',
      });
    });

    it('renders scope list', () => {
      expect(wrapper.text()).toMatch(/API\s+READ USER/);
    });
  });
});
