import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import toggleWhatsNewDrawer from '~/whats_new';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL, CONTRIBUTE_URL } from '~/constants';
import { useLocalStorageSpy, useWithoutLocalStorage } from 'helpers/local_storage_helper';
import { STORAGE_KEY } from '~/whats_new/utils/notification';
import { mockTracking } from 'helpers/tracking_helper';
import { sidebarData } from '../mock_data';

jest.mock('~/whats_new');

describe('HelpCenter component', () => {
  let wrapper;
  let trackingSpy;

  const GlEmoji = { template: '<img/>' };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroup = (i = 0) => {
    return wrapper.findAllComponents(GlDisclosureDropdownGroup).at(i);
  };
  const withinComponent = () => within(wrapper.element);
  const findButton = (name) => withinComponent().getByRole('button', { name });
  const findWhatsNew = () => wrapper.findByTestId('sidebar-whatsnew-button');
  const findNotificationCount = () => wrapper.findByTestId('notification-count');

  const createWrapper = (sidebarDataOverride = sidebarData, provide = {}) => {
    wrapper = mountExtended(HelpCenter, {
      propsData: { sidebarData: sidebarDataOverride },
      stubs: { GlEmoji },
      provide: {
        isSaas: false,
        ...provide,
      },
    });
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const trackingAttrs = (label) => {
    return {
      'data-track-action': 'click_link',
      'data-track-property': 'nav_help_menu',
      'data-track-label': label,
    };
  };

  const PRIVACY_HELP_ITEM = {
    text: HelpCenter.i18n.privacy,
    href: `${PROMO_URL}/privacy`,
    extraAttrs: trackingAttrs('privacy'),
  };

  const getDefaultHelpItems = (customSidebarData = sidebarData) => [
    { text: HelpCenter.i18n.help, href: helpPagePath(), extraAttrs: trackingAttrs('help') },
    {
      text: HelpCenter.i18n.support,
      href: customSidebarData.support_path,
      extraAttrs: trackingAttrs('support'),
    },
    {
      text: HelpCenter.i18n.docs,
      href: customSidebarData.docs_path,
      extraAttrs: trackingAttrs('gitlab_documentation'),
    },
    {
      text: HelpCenter.i18n.plans,
      href: customSidebarData.compare_plans_url,
      extraAttrs: trackingAttrs('compare_gitlab_plans'),
    },
    {
      text: HelpCenter.i18n.forum,
      href: FORUM_URL,
      extraAttrs: trackingAttrs('community_forum'),
    },
    {
      text: HelpCenter.i18n.contribute,
      href: CONTRIBUTE_URL,
      extraAttrs: trackingAttrs('contribute_to_gitlab'),
    },
    {
      text: HelpCenter.i18n.feedback,
      href: `${PROMO_URL}/submit-feedback`,
      extraAttrs: trackingAttrs('submit_feedback'),
    },
  ];

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders menu items', () => {
      expect(findWhatsNew().exists()).toBe(true);
      expect(findDropdownGroup(0).props('group').items).toEqual(getDefaultHelpItems());

      expect(findDropdownGroup(1).props('group').items).toEqual([
        expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
      ]);
    });

    it('does not render privacy item if not in SaaS mode', () => {
      createWrapper(sidebarData, { isSaas: false });

      expect(findDropdownGroup(0).props('group').items).toEqual(getDefaultHelpItems());
    });

    it('renders privacy item if in SaaS mode', () => {
      createWrapper(sidebarData, { isSaas: true });

      expect(findDropdownGroup(0).props('group').items).toEqual([
        ...getDefaultHelpItems(),
        PRIVACY_HELP_ITEM,
      ]);
    });

    describe('when localStorage is disabled', () => {
      useWithoutLocalStorage();

      beforeEach(() => {
        createWrapper();
      });

      it('renders component without errors', () => {
        expect(findDropdown().exists()).toBe(true);
      });
    });

    describe('compare plans URL', () => {
      it('uses the compare_plans_url provided in sidebarData', () => {
        const customSidebarData = {
          ...sidebarData,
          compare_plans_url: '/custom/billing/path',
        };

        createWrapper(customSidebarData);

        const helpItems = findDropdownGroup(0).props('group').items;
        const plansItem = helpItems.find((item) => item.text === HelpCenter.i18n.plans);

        expect(plansItem.href).toBe('/custom/billing/path');
      });

      it('uses the compare_plans_url from sidebarData', () => {
        createWrapper();

        const helpItems = findDropdownGroup(0).props('group').items;
        const plansItem = helpItems.find((item) => item.text === HelpCenter.i18n.plans);

        expect(plansItem.href).toBe(sidebarData.compare_plans_url);
      });
    });

    it('passes custom offset to the dropdown', () => {
      expect(findDropdown().props('dropdownOffset')).toEqual({
        mainAxis: 4,
      });
    });

    describe('with matching version digest in local storage', () => {
      useLocalStorageSpy();

      beforeEach(() => {
        window.localStorage.setItem(STORAGE_KEY, 1);
        createWrapper(sidebarData);
      });

      it('renders menu items', () => {
        expect(findDropdownGroup(0).props('group').items).toEqual(getDefaultHelpItems());

        expect(findDropdownGroup(1).props('group').items).toEqual([
          expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
          expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
        ]);
      });
    });

    describe('with GitLab version check feature enabled', () => {
      beforeEach(() => {
        createWrapper({
          ...sidebarData,
          show_version_check: true,
        });
      });

      it('shows version information as first item', () => {
        expect(findDropdownGroup(0).props('group').items).toEqual([
          {
            text: HelpCenter.i18n.version,
            href: helpPagePath('update/_index.md'),
            version: '16.0',
            extraAttrs: trackingAttrs('version_help_dropdown'),
          },
        ]);
      });
    });

    describe('when Terms of Service and Data Privacy is set', () => {
      it('shows link to Terms of Service and Data Privacy', () => {
        const customSidebarData = {
          ...sidebarData,
          terms: '/-/users/terms',
        };

        createWrapper(customSidebarData);

        expect(findDropdownGroup(0).props('group').items).toEqual([
          ...getDefaultHelpItems(customSidebarData),
          expect.objectContaining({
            text: HelpCenter.i18n.terms,
            href: '/-/users/terms',
            extraAttrs: {
              ...trackingAttrs('terms'),
            },
          }),
        ]);
      });

      it('does not show link to Terms of Service and Data Privacy on SaaS even if it is set', () => {
        const customSidebarData = {
          ...sidebarData,
          terms: '/-/users/terms',
        };

        createWrapper(customSidebarData, { isSaas: true });

        expect(findDropdownGroup(0).props('group').items).toEqual([
          ...getDefaultHelpItems(customSidebarData),
          PRIVACY_HELP_ITEM,
        ]);
      });
    });

    describe('when Terms of Service and Data Privacy is undefined', () => {
      beforeEach(() => {
        createWrapper({
          ...sidebarData,
          terms: undefined,
        });
      });

      it('does not show link to Terms of Service and Data Privacy', () => {
        const menuItems = findDropdownGroup(0)
          .props('group')
          .items.map(({ text }) => text);
        expect(menuItems).not.toContain('Terms and privacy');
      });
    });

    describe('keyboard shortcuts', () => {
      let button;

      beforeEach(() => {
        button = findButton('Keyboard shortcuts');
      });

      it('shows the keyboard shortcuts modal', () => {
        expect(button.classList.contains('js-shortcuts-modal-trigger')).toBe(true);
      });

      it('has Snowplow tracking attributes', () => {
        expect(findButton('Keyboard shortcuts').dataset).toEqual(
          expect.objectContaining({
            trackAction: 'click_button',
            trackLabel: 'keyboard_shortcuts_help',
            trackProperty: 'nav_help_menu',
          }),
        );
      });
    });

    describe("What's new", () => {
      beforeEach(() => {
        createWrapper({
          ...sidebarData,
          show_version_check: true,
        });

        findButton("What's new").click();
      });

      it("shows the What's new slideout", () => {
        expect(toggleWhatsNewDrawer).toHaveBeenCalledWith(
          sidebarData.whats_new_version_digest,
          expect.any(Function),
        );
      });

      it("shows the existing What's new slideout instance on subsequent clicks", () => {
        findButton("What's new").click();
        expect(toggleWhatsNewDrawer).toHaveBeenCalledTimes(2);
        expect(toggleWhatsNewDrawer).toHaveBeenLastCalledWith();
      });

      it('has Snowplow tracking attributes', () => {
        createWrapper({
          ...sidebarData,
          display_whats_new: true,
        });

        expect(findButton("What's new").dataset).toEqual(
          expect.objectContaining({
            trackAction: 'click_button',
            trackLabel: 'whats_new',
            trackProperty: 'nav_whats_new',
          }),
        );
      });
    });

    describe("What's new notification", () => {
      describe('when setting is disabled', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            display_whats_new: false,
          });
        });

        it('does not render notification count', () => {
          expect(findNotificationCount().exists()).toBe(false);
        });
      });

      describe('when setting is enabled', () => {
        useLocalStorageSpy();

        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            display_whats_new: true,
          });
        });

        it('renders notification count', () => {
          expect(findNotificationCount().exists()).toBe(true);
        });

        describe("when What's new drawer is opened", () => {
          beforeEach(() => {
            findButton("What's new").click();
          });

          it('renders notification count', () => {
            expect(findNotificationCount().exists()).toBe(true);
          });
        });

        describe('with matching version digest in local storage', () => {
          beforeEach(() => {
            window.localStorage.setItem(STORAGE_KEY, 1);
            createWrapper({
              ...sidebarData,
              display_whats_new: true,
            });
          });

          it('does not render notification count', () => {
            expect(findNotificationCount().exists()).toBe(false);
          });
        });
      });
    });

    describe('dropdown toggle', () => {
      it('tracks Snowplow event when dropdown is shown', () => {
        findDropdown().vm.$emit('shown');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: 'show_help_dropdown',
          property: 'nav_help_menu',
        });
      });

      it('tracks Snowplow event when dropdown is hidden', () => {
        findDropdown().vm.$emit('hidden');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: 'hide_help_dropdown',
          property: 'nav_help_menu',
        });
      });
    });
  });
});
