import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import OAuthDomainMismatchError from '~/ide/components/oauth_domain_mismatch_error.vue';

const MOCK_CALLBACK_URLS = [
  {
    base: 'https://example1.com/',
  },
  {
    base: 'https://example2.com/',
  },
  {
    base: 'https://example3.com/relative-path/',
  },
];
const MOCK_CALLBACK_URL = 'https://example.com';
const MOCK_PATH_NAME = 'path/to/ide';

const EXPECTED_DROPDOWN_ITEMS = MOCK_CALLBACK_URLS.map(({ base }) => ({
  text: base,
  href: `${base}${MOCK_PATH_NAME}`,
}));

describe('OAuthDomainMismatchError', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const createWrapper = (props = {}) => {
    wrapper = mount(OAuthDomainMismatchError, {
      propsData: {
        expectedCallbackUrl: MOCK_CALLBACK_URL,
        callbackUrls: MOCK_CALLBACK_URLS,
        ...props,
      },
    });
  };

  beforeEach(() => {
    setWindowLocation(`/${MOCK_PATH_NAME}`);
  });

  describe('single callback URL domain passed', () => {
    beforeEach(() => {
      createWrapper({
        callbackUrls: MOCK_CALLBACK_URLS.slice(0, 1),
      });
    });

    it('renders expected callback URL message', () => {
      expect(wrapper.text()).toContain(
        `Could not find a callback URL entry for ${MOCK_CALLBACK_URL}.`,
      );
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('renders button with correct attributes', () => {
      const button = findButton();
      expect(button.exists()).toBe(true);
      const baseUrl = MOCK_CALLBACK_URLS[0].base;
      expect(button.text()).toContain(baseUrl);
      expect(button.attributes('href')).toBe(`${baseUrl}${MOCK_PATH_NAME}`);
    });
  });

  describe('multiple callback URL domains passed', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders dropdown with correct items', () => {
      const dropdown = findDropdown();

      expect(dropdown.exists()).toBe(true);
      expect(dropdown.props('items')).toStrictEqual(EXPECTED_DROPDOWN_ITEMS);
    });
  });

  describe('with erroneous callback from current origin', () => {
    beforeEach(() => {
      createWrapper({
        callbackUrls: MOCK_CALLBACK_URLS.concat({
          base: `${TEST_HOST}/foo`,
        }),
      });
    });

    it('filters out item with current origin', () => {
      expect(findDropdown().props('items')).toStrictEqual(EXPECTED_DROPDOWN_ITEMS);
    });
  });

  describe('when no callback URL passed', () => {
    beforeEach(() => {
      createWrapper({
        callbackUrls: [],
      });
    });

    it('does not render dropdown or button', () => {
      expect(findDropdown().exists()).toBe(false);
      expect(findButton().exists()).toBe(false);
    });
  });
});
