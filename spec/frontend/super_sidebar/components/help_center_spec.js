import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import toggleWhatsNewDrawer from '~/whats_new';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DOMAIN, PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { STORAGE_KEY } from '~/whats_new/utils/notification';
import { helpCenterState } from '~/super_sidebar/constants';
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

  // eslint-disable-next-line no-shadow
  const createWrapper = (sidebarData) => {
    wrapper = mountExtended(HelpCenter, {
      propsData: { sidebarData },
      stubs: { GlEmoji },
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

  const DEFAULT_HELP_ITEMS = [
    { text: HelpCenter.i18n.help, href: helpPagePath(), extraAttrs: trackingAttrs('help') },
    {
      text: HelpCenter.i18n.support,
      href: sidebarData.support_path,
      extraAttrs: trackingAttrs('support'),
    },
    {
      text: HelpCenter.i18n.docs,
      href: `https://docs.${DOMAIN}`,
      extraAttrs: trackingAttrs('gitlab_documentation'),
    },
    {
      text: HelpCenter.i18n.plans,
      href: `${PROMO_URL}/pricing`,
      extraAttrs: trackingAttrs('compare_gitlab_plans'),
    },
    {
      text: HelpCenter.i18n.forum,
      href: `https://forum.${DOMAIN}/`,
      extraAttrs: trackingAttrs('community_forum'),
    },
    {
      text: HelpCenter.i18n.contribute,
      href: helpPagePath('', { anchor: 'contributing-to-gitlab' }),
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
      createWrapper(sidebarData);
    });

    it('renders menu items', () => {
      expect(findDropdownGroup(0).props('group').items).toEqual(DEFAULT_HELP_ITEMS);

      expect(findDropdownGroup(1).props('group').items).toEqual([
        expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
        expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
      ]);
    });

    it('passes popper options to the dropdown', () => {
      expect(findDropdown().props('popperOptions')).toEqual({
        modifiers: [{ name: 'offset', options: { offset: [-4, 4] } }],
      });
    });

    describe('with show_tanuki_bot true', () => {
      beforeEach(() => {
        createWrapper({ ...sidebarData, show_tanuki_bot: true });
        jest.spyOn(wrapper.vm.$refs.dropdown, 'close');
      });

      it('shows Ask GitLab Chat with the help items', () => {
        expect(findDropdownGroup(0).props('group').items).toEqual([
          expect.objectContaining({
            icon: 'tanuki',
            text: HelpCenter.i18n.chat,
            extraAttrs: trackingAttrs('tanuki_bot_help_dropdown'),
          }),
          ...DEFAULT_HELP_ITEMS,
        ]);
      });

      describe('when Ask GitLab Chat button is clicked', () => {
        beforeEach(() => {
          findButton('Ask GitLab Chat').click();
        });

        it('closes the dropdown', () => {
          expect(wrapper.vm.$refs.dropdown.close).toHaveBeenCalled();
        });

        it('sets helpCenterState.showTanukiBotChatDrawer to true', () => {
          expect(helpCenterState.showTanukiBotChatDrawer).toBe(true);
        });
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
            href: helpPagePath('update/index'),
            version: '16.0',
            extraAttrs: trackingAttrs('version_help_dropdown'),
          },
        ]);
      });
    });

    describe('showKeyboardShortcuts', () => {
      let button;

      beforeEach(() => {
        jest.spyOn(wrapper.vm.$refs.dropdown, 'close');

        button = findButton('Keyboard shortcuts ?');
      });

      it('closes the dropdown', () => {
        button.click();
        expect(wrapper.vm.$refs.dropdown.close).toHaveBeenCalled();
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
        jest.spyOn(wrapper.vm.$refs.dropdown, 'close');
        beforeEach(() => {
          createWrapper({ ...sidebarData, show_version_check: true });
        });
        findButton("What's new 5").click();
      });

      it('closes the dropdown', () => {
        expect(wrapper.vm.$refs.dropdown.close).toHaveBeenCalled();
      });

      it('shows the "What\'s new" slideout', () => {
        expect(toggleWhatsNewDrawer).toHaveBeenCalledWith(expect.any(Object));
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

        it('is false', () => {
          expect(wrapper.vm.showWhatsNewNotification).toBe(false);
        });
      });

      describe('when setting is enabled', () => {
        useLocalStorageSpy();

        beforeEach(() => {
          createWrapper({ ...sidebarData, display_whats_new: true });
        });

        it('is true', () => {
          expect(wrapper.vm.showWhatsNewNotification).toBe(true);
        });

        describe('when "What\'s new" drawer got opened', () => {
          beforeEach(() => {
            findButton("What's new 5").click();
          });

          it('is false', () => {
            expect(wrapper.vm.showWhatsNewNotification).toBe(false);
          });
        });

        describe('with matching version digest in local storage', () => {
          beforeEach(() => {
            window.localStorage.setItem(STORAGE_KEY, 1);
            createWrapper({ ...sidebarData, display_whats_new: true });
          });

          it('is false', () => {
            expect(wrapper.vm.showWhatsNewNotification).toBe(false);
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
