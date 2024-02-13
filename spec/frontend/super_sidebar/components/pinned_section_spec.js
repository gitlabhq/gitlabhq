import { nextTick } from 'vue';
import Cookies from '~/lib/utils/cookies';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PinnedSection from '~/super_sidebar/components/pinned_section.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import NavItemLink from '~/super_sidebar/components/nav_item_link.vue';
import {
  PINNED_NAV_STORAGE_KEY,
  SIDEBAR_PINS_EXPANDED_COOKIE,
  SIDEBAR_COOKIE_EXPIRATION,
} from '~/super_sidebar/constants';
import { setCookie } from '~/lib/utils/common_utils';

jest.mock('@floating-ui/dom');
jest.mock('~/lib/utils/common_utils', () => ({
  getCookie: jest.requireActual('~/lib/utils/common_utils').getCookie,
  setCookie: jest.fn(),
}));

describe('PinnedSection component', () => {
  let wrapper;

  const findToggle = () => wrapper.find('button');

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(PinnedSection, {
      propsData: {
        items: [{ title: 'Pin 1', href: '/page1' }],
        ...props,
      },
    });
  };

  describe('expanded', () => {
    describe('when cookie is not set', () => {
      it('is expanded by default', () => {
        createWrapper();
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });
    });

    describe('when cookie is set to false', () => {
      beforeEach(() => {
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'false');
        createWrapper();
      });

      it('is collapsed', () => {
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(false);
      });

      it('updates the cookie when expanding the section', async () => {
        findToggle().trigger('click');
        await nextTick();

        expect(setCookie).toHaveBeenCalledWith(SIDEBAR_PINS_EXPANDED_COOKIE, true, {
          expires: SIDEBAR_COOKIE_EXPIRATION,
        });
      });
    });

    describe('when cookie is set to true', () => {
      beforeEach(() => {
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'true');
        createWrapper();
      });

      it('is expanded', () => {
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });

      it('updates the cookie when collapsing the section', async () => {
        findToggle().trigger('click');
        await nextTick();

        expect(setCookie).toHaveBeenCalledWith(SIDEBAR_PINS_EXPANDED_COOKIE, false, {
          expires: SIDEBAR_COOKIE_EXPIRATION,
        });
      });
    });

    describe('when a pinned nav item was used before', () => {
      beforeEach(() => {
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'false');
        createWrapper({ wasPinnedNav: true });
      });

      it('is expanded', () => {
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });
    });
  });

  describe('hasFlyout prop', () => {
    describe.each([true, false])(`when %s`, (hasFlyout) => {
      beforeEach(() => {
        createWrapper({ hasFlyout });
      });

      it(`passes ${hasFlyout} to the section's hasFlyout prop`, () => {
        expect(wrapper.findComponent(MenuSection).props('hasFlyout')).toBe(hasFlyout);
      });
    });
  });

  describe('ambiguous settings names', () => {
    it('get renamed to be unambiguous', () => {
      createWrapper({
        items: [
          { title: 'CI/CD', id: 'ci_cd' },
          { title: 'Merge requests', id: 'merge_request_settings' },
          { title: 'Monitor', id: 'monitor' },
          { title: 'Repository', id: 'repository' },
          { title: 'Repository', id: 'code' },
          { title: 'Something else', id: 'not_a_setting' },
        ],
      });

      expect(
        wrapper
          .findComponent(MenuSection)
          .props('item')
          .items.map((i) => i.title),
      ).toEqual([
        'CI/CD settings',
        'Merge requests settings',
        'Monitor settings',
        'Repository settings',
        'Repository',
        'Something else',
      ]);
    });
  });

  describe('click on a pinned nav item', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('stores pinned nav usage in sessionStorage', () => {
      expect(window.sessionStorage.getItem(PINNED_NAV_STORAGE_KEY)).toBe(null);
      wrapper.findComponent(NavItemLink).vm.$emit('nav-link-click');
      expect(window.sessionStorage.getItem(PINNED_NAV_STORAGE_KEY)).toBe('true');
    });
  });
});
