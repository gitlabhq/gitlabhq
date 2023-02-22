import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import toggleWhatsNewDrawer from '~/whats_new';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { STORAGE_KEY } from '~/whats_new/utils/notification';
import { sidebarData } from '../mock_data';

jest.mock('~/whats_new');

describe('HelpCenter component', () => {
  let wrapper;

  const GlEmoji = { template: '<img/>' };

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
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper(sidebarData);
    });

    it('renders menu items', () => {
      expect(findDropdownGroup(0).props('group').items).toEqual([
        { text: HelpCenter.i18n.help, href: helpPagePath() },
        { text: HelpCenter.i18n.support, href: sidebarData.support_path },
        { text: HelpCenter.i18n.docs, href: 'https://docs.gitlab.com' },
        { text: HelpCenter.i18n.plans, href: `${PROMO_URL}/pricing` },
        { text: HelpCenter.i18n.forum, href: 'https://forum.gitlab.com/' },
        {
          text: HelpCenter.i18n.contribute,
          href: helpPagePath('', { anchor: 'contributing-to-gitlab' }),
        },
        { text: HelpCenter.i18n.feedback, href: 'https://about.gitlab.com/submit-feedback' },
      ]);

      expect(findDropdownGroup(1).props('group').items).toEqual([
        expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
        expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
      ]);
    });

    describe('with Gitlab version check feature enabled', () => {
      beforeEach(() => {
        createWrapper({ ...sidebarData, show_version_check: true });
      });

      it('shows version information as first item', () => {
        expect(findDropdownGroup(0).props('group').items).toEqual([
          { text: HelpCenter.i18n.version, href: helpPagePath('update/index'), version: '16.0' },
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
    });

    describe('showWhatsNew', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm.$refs.dropdown, 'close');
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
  });
});
