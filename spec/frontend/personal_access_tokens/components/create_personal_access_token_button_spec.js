import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CreatePersonalAccessTokenButton from '~/personal_access_tokens/components/create_personal_access_token_button.vue';

describe('CreatePersonalAccessTokenButton', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CreatePersonalAccessTokenButton);
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findFineGrainedTokenOption = () => findDropdownItems().at(0);
  const findLegacyTokenOption = () => findDropdownItems().at(1);
  const findBadge = () => findFineGrainedTokenOption().findComponent(GlBadge);

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
    expect(findDropdownItems()).toHaveLength(2);
  });

  describe('fine-grained token option', () => {
    it('displays the correct title', () => {
      expect(findFineGrainedTokenOption().text()).toContain('Fine-grained token');
    });

    it('displays the beta badge', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().props('variant')).toBe('info');
      expect(findBadge().text()).toBe('Beta');
    });

    it('displays the correct description', () => {
      expect(findFineGrainedTokenOption().text()).toContain(
        'Limit scope to specific groups and projects and fine-grained permissions to resources.',
      );
    });
  });

  describe('legacy token option', () => {
    it('displays the correct title', () => {
      expect(findLegacyTokenOption().text()).toContain('Broad-access token');
    });

    it('displays the correct description', () => {
      expect(findLegacyTokenOption().text()).toContain(
        'Scoped to all groups and projects with broad permissions to resources.',
      );
    });
  });
});
