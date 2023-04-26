import { nextTick } from 'vue';
import Cookies from '~/lib/utils/cookies';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PinnedSection from '~/super_sidebar/components/pinned_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { SIDEBAR_PINS_EXPANDED_COOKIE, SIDEBAR_COOKIE_EXPIRATION } from '~/super_sidebar/constants';
import { setCookie } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils', () => ({
  getCookie: jest.requireActual('~/lib/utils/common_utils').getCookie,
  setCookie: jest.fn(),
}));

describe('PinnedSection component', () => {
  let wrapper;

  const findToggle = () => wrapper.find('button');

  const createWrapper = () => {
    wrapper = mountExtended(PinnedSection, {
      propsData: {
        items: [{ title: 'Pin 1', href: '/page1' }],
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
  });
});
