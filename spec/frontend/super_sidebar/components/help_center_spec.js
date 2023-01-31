import { GlDisclosureDropdown } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import toggleWhatsNewDrawer from '~/whats_new';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { sidebarData } from '../mock_data';

jest.mock('~/whats_new');

describe('HelpCenter component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const withinComponent = () => within(wrapper.element);
  const findButton = (name) => withinComponent().getByRole('button', { name });

  const createWrapper = () => {
    wrapper = mountExtended(HelpCenter, {
      propsData: { sidebarData },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders menu items', () => {
      expect(findDropdown().props('items')[0].items).toEqual([
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

      expect(findDropdown().props('items')[1].items).toEqual([
        expect.objectContaining({ text: HelpCenter.i18n.shortcuts }),
        expect.objectContaining({ text: HelpCenter.i18n.whatsnew }),
      ]);
    });

    describe('showKeyboardShortcuts', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm.$refs.dropdown, 'close');
        window.toggleShortcutsHelp = jest.fn();
        findButton('Keyboard shortcuts').click();
      });

      it('closes the dropdown', () => {
        expect(wrapper.vm.$refs.dropdown.close).toHaveBeenCalled();
      });

      it('shows the keyboard shortcuts modal', () => {
        expect(window.toggleShortcutsHelp).toHaveBeenCalled();
      });
    });

    describe('showWhatsNew', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm.$refs.dropdown, 'close');
        findButton("What's new").click();
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
  });
});
