import { GlButton, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import OAuthDomainMismatchError from '~/ide/components/oauth_domain_mismatch_error.vue';

const MOCK_CALLBACK_URL_ORIGIN = 'https://example1.com';
const MOCK_PATH_NAME = '/path/to/ide';

describe('OAuthDomainMismatchError', () => {
  useMockLocationHelper();

  let wrapper;
  let originalLocation;

  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItems = () => wrapper.findAllComponents(GlListboxItem);

  const createWrapper = (props = {}) => {
    wrapper = mount(OAuthDomainMismatchError, {
      propsData: {
        callbackUrlOrigins: [MOCK_CALLBACK_URL_ORIGIN],
        ...props,
      },
    });
  };

  beforeEach(() => {
    originalLocation = window.location;
    window.location.pathname = MOCK_PATH_NAME;
  });

  afterEach(() => {
    window.location = originalLocation;
  });

  describe('single callback URL domain passed', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('reloads page with correct url on button click', async () => {
      findButton().vm.$emit('click');
      await nextTick();

      expect(window.location.replace).toHaveBeenCalledTimes(1);
      expect(window.location.replace).toHaveBeenCalledWith(
        new URL(MOCK_CALLBACK_URL_ORIGIN + MOCK_PATH_NAME).toString(),
      );
    });
  });

  describe('multiple callback URL domains passed', () => {
    const MOCK_CALLBACK_URL_ORIGINS = [MOCK_CALLBACK_URL_ORIGIN, 'https://example2.com'];

    beforeEach(() => {
      createWrapper({ callbackUrlOrigins: MOCK_CALLBACK_URL_ORIGINS });
    });

    it('renders dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders dropdown items', () => {
      const dropdownItems = findDropdownItems();
      expect(dropdownItems.length).toBe(MOCK_CALLBACK_URL_ORIGINS.length);
      expect(dropdownItems.at(0).text()).toBe(MOCK_CALLBACK_URL_ORIGINS[0]);
      expect(dropdownItems.at(1).text()).toBe(MOCK_CALLBACK_URL_ORIGINS[1]);
    });

    it('reloads page with correct url on dropdown item click', async () => {
      const dropdownItem = findDropdownItems().at(0);
      dropdownItem.vm.$emit('select', MOCK_CALLBACK_URL_ORIGIN);
      await nextTick();

      expect(window.location.replace).toHaveBeenCalledTimes(1);
      expect(window.location.replace).toHaveBeenCalledWith(
        new URL(MOCK_CALLBACK_URL_ORIGIN + MOCK_PATH_NAME).toString(),
      );
    });
  });
});
