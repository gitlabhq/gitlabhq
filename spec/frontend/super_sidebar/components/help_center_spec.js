import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import toggleWhatsNewDrawer from '~/whats_new';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL } from '~/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
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
  const findNotificationDot = () => wrapper.findByTestId('notification-dot');

  // eslint-disable-next-line no-shadow
  const createWrapper = (sidebarData, provide = {}) => {
    wrapper = mountExtended(HelpCenter, {
      propsData: { sidebarData },
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

  const DEFAULT_HELP_ITEMS = [
    { text: HelpCenter.i18n.help, href: helpPagePath(), extraAttrs: trackingAttrs('help') },
    {
      text: HelpCenter.i18n.support,
      href: sidebarData.support_path,
      extraAttrs: trackingAttrs('support'),
    },
    {
      text: HelpCenter.i18n.docs,
      href: sidebarData.docs_path,
      extraAttrs: trackingAttrs('gitlab_documentation'),
    },
    {
      text: HelpCenter.i18n.plans,
      href: `${PROMO_URL}/pricing`,
      extraAttrs: trackingAttrs('compare_gitlab_plans'),
    },
    {
      text: HelpCenter.i18n.forum,
      href: FORUM_URL,
      extraAttrs: trackingAttrs('community_forum'),
    },
    {
      text: HelpCenter.i18n.contribute,
      href: helpPagePath('', { anchor: 'contribute-to-gitlab' }),
      extraAttrs: trackingAttrs('contribute_to_gitlab'),
    },
    {
      text: HelpCenter.i18n.feedback,
      href: `${PROMO_URL}/submit-feedback`,
      extraAttrs: trackingAttrs('submit_feedback'),
    },
  ];

  const ALL_HELP_ITEMS = [...DEFAULT_HELP_ITEMS, PRIVACY_HELP_ITEM];

  describe('default', () => {
    beforeEach(() => {
      createWrapper(sidebarData);
    });

    it('renders menu items', () => {
      expect(findDropdownGroup(0).props('group').items).toEqual(DEFAULT_HELP_ITEMS);

      expect(findDropdownGroup(1).props('group').items).toEqual([
        expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
        expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
      ]);
    });

    it('doesn`t render privacy item if not in `SaaS` mode', () => {
      createWrapper({ ...sidebarData }, { isSaas: false });

      expect(findDropdownGroup(0).props('group').items).toEqual(DEFAULT_HELP_ITEMS);
    });

    it('renders privacy item if in `SaaS` mode', () => {
      createWrapper({ ...sidebarData }, { isSaas: true });

      expect(findDropdownGroup(0).props('group').items).toEqual(ALL_HELP_ITEMS);
    });

    it('passes custom offset to the dropdown', () => {
      expect(findDropdown().props('dropdownOffset')).toEqual({
        mainAxis: 4,
      });
    });

    describe('with Gitlab version check feature enabled', () => {
      beforeEach(() => {
        createWrapper({ ...sidebarData, show_version_check: true });
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

    describe('if Terms of Service and Data Privacy is set', () => {
      it('shows link to Terms of Service and Data Privacy', () => {
        createWrapper({ ...sidebarData, terms: '/-/users/terms' });

        expect(findDropdownGroup(0).props('group').items).toEqual([
          ...DEFAULT_HELP_ITEMS,
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
        createWrapper({ ...sidebarData, terms: '/-/users/terms' }, { isSaas: true });

        expect(findDropdownGroup(0).props('group').items).toEqual([
          ...DEFAULT_HELP_ITEMS,
          PRIVACY_HELP_ITEM,
        ]);
      });
    });

    describe('If Terms of Service and Data Privacy is undefined', () => {
      beforeEach(() => {
        createWrapper({ ...sidebarData, terms: undefined });
      });

      it('does not show link to Terms of Service and Data Privacy', () => {
        const menuItems = findDropdownGroup(0)
          .props('group')
          .items.map(({ text }) => text);
        expect(menuItems).not.toContain('Terms and privacy');
      });
    });

    describe('showKeyboardShortcuts', () => {
      let button;

      beforeEach(() => {
        button = findButton('Keyboard shortcuts ?');
      });

      it('shows the keyboard shortcuts modal', () => {
        // This relies on the event delegation set up by the Shortcuts class in
        // ~/behaviors/shortcuts/shortcuts.js.
        expect(button.classList.contains('js-shortcuts-modal-trigger')).toBe(true);
      });

      it('should have Snowplow tracking attributes', () => {
        expect(findButton('Keyboard shortcuts ?').dataset).toEqual(
          expect.objectContaining({
            trackAction: 'click_button',
            trackLabel: 'keyboard_shortcuts_help',
            trackProperty: 'nav_help_menu',
          }),
        );
      });
    });

    describe('showWhatsNew', () => {
      beforeEach(() => {
        createWrapper({ ...sidebarData, show_version_check: true });

        findButton("What's new 5").click();
      });

      it('shows the "What\'s new" slideout', () => {
        expect(toggleWhatsNewDrawer).toHaveBeenCalledWith(sidebarData.whats_new_version_digest);
      });

      it('shows the existing "What\'s new" slideout instance on subsequent clicks', () => {
        findButton("What's new").click();
        expect(toggleWhatsNewDrawer).toHaveBeenCalledTimes(2);
        expect(toggleWhatsNewDrawer).toHaveBeenLastCalledWith();
      });

      it('should have Snowplow tracking attributes', () => {
        createWrapper({ ...sidebarData, display_whats_new: true });

        expect(findButton("What's new 5").dataset).toEqual(
          expect.objectContaining({
            trackAction: 'click_button',
            trackLabel: 'whats_new',
            trackProperty: 'nav_help_menu',
          }),
        );
      });
    });

    describe('shouldShowWhatsNewNotification', () => {
      describe('when setting is disabled', () => {
        beforeEach(() => {
          createWrapper({ ...sidebarData, display_whats_new: false });
        });

        it('does not render notification dot', () => {
          expect(findNotificationDot().exists()).toBe(false);
        });
      });

      describe('when setting is enabled', () => {
        useLocalStorageSpy();

        beforeEach(() => {
          createWrapper({ ...sidebarData, display_whats_new: true });
        });

        it('renders notification dot', () => {
          expect(findNotificationDot().exists()).toBe(true);
        });

        describe('when "What\'s new" drawer got opened', () => {
          beforeEach(() => {
            findButton("What's new 5").click();
          });

          it('does not render notification dot', () => {
            expect(findNotificationDot().exists()).toBe(false);
          });
        });

        describe('with matching version digest in local storage', () => {
          beforeEach(() => {
            window.localStorage.setItem(STORAGE_KEY, 1);
            createWrapper({ ...sidebarData, display_whats_new: true });
          });

          it('does not render notification dot', () => {
            expect(findNotificationDot().exists()).toBe(false);
          });
        });
      });
    });

    describe('toggle dropdown', () => {
      it('should track Snowplow event when dropdown is shown', () => {
        findDropdown().vm.$emit('shown');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: 'show_help_dropdown',
          property: 'nav_help_menu',
        });
      });

      it('should track Snowplow event when dropdown is hidden', () => {
        findDropdown().vm.$emit('hidden');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
          label: 'hide_help_dropdown',
          property: 'nav_help_menu',
        });
      });
    });
  });
});
