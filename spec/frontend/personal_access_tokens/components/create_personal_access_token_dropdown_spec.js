import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CreatePersonalAccessTokenDropdown from '~/personal_access_tokens/components/create_personal_access_token_dropdown.vue';

describe('CreatePersonalAccessTokenDropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CreatePersonalAccessTokenDropdown, {
      provide: {
        accessTokenGranularNewUrl: '/granular/new',
        accessTokenLegacyNewUrl: '/legacy/new',
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findFineGrainedTokenOption = () => findDropdown().props('items').at(0);
  const findLegacyTokenOption = () => findDropdown().props('items').at(1);

  beforeEach(() => {
    createComponent();
  });

  it('renders a disclosure dropdown', () => {
    expect(findDropdown().exists()).toBe(true);
  });

  it('sets correct dropdown props', () => {
    expect(findDropdown().props()).toMatchObject({
      toggleText: 'Generate token',
      placement: 'bottom-end',
      fluidWidth: true,
    });
  });

  it('renders two dropdown items', () => {
    expect(findDropdown().props('items')).toHaveLength(2);
  });

  describe('fine-grained token option', () => {
    it('displays the correct title', () => {
      expect(findFineGrainedTokenOption().text).toBe('Fine-grained token');
    });

    it('displays the beta badge', () => {
      expect(findFineGrainedTokenOption().badge).toBe('Beta');
    });

    it('displays the correct description', () => {
      expect(findFineGrainedTokenOption().description).toBe(
        'Limit scope to specific groups and projects and fine-grained permissions to resources.',
      );
    });

    it('displays the correct link', () => {
      expect(findFineGrainedTokenOption().href).toBe('/granular/new');
    });
  });

  describe('legacy token option', () => {
    it('displays the correct title', () => {
      expect(findLegacyTokenOption().text).toContain('Legacy token');
    });

    it('displays the correct description', () => {
      expect(findLegacyTokenOption().description).toContain(
        'Scoped to all groups and projects with broad permissions to resources.',
      );
    });

    it('displays the correct link', () => {
      expect(findLegacyTokenOption().href).toBe('/legacy/new');
    });
  });
});
