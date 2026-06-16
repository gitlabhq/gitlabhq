import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import WhatsNewForYouMenuItem from '~/whats_new/components/whats_new_for_you_menu_item.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL, CONTRIBUTE_URL } from '~/constants';
import { mockTracking } from 'helpers/tracking_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import HelpCenterUpgradeSubscription from 'ee_component/super_sidebar/components/help_center_upgrade_subscription.vue';
import { sidebarData } from '../mock_data';

describe('HelpCenter component', () => {
  let wrapper;
  let trackingSpy;
  let origGl;

  beforeEach(() => {
    origGl = window.gl;
    window.gl = { ...window.gl, experiments: {} };
  });

  afterEach(() => {
    window.gl = origGl;
  });

  const GlEmoji = { template: '<img/>' };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findAllGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findDropdownGroup = (i = 0) => findAllGroups().at(i);
  const withinComponent = () => within(wrapper.element);
  const findButton = (name) => withinComponent().getByRole('button', { name });
  const findUpgradeButton = () => wrapper.findComponent(HelpCenterUpgradeSubscription);
  const findWhatsNewForYouMenuItem = () => wrapper.findComponent(WhatsNewForYouMenuItem);

  const createWrapper = (sidebarDataOverride = sidebarData, provide = {}) => {
    wrapper = mountExtended(HelpCenter, {
      propsData: { sidebarData: sidebarDataOverride },
      stubs: { GlEmoji, HelpCenterUpgradeSubscription: true },
      provide: {
        isSaas: false,
        isIconOnly: false,
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
      text: HelpCenter.i18n.university,
      href: customSidebarData.university_path,
      extraAttrs: trackingAttrs('gitlab_university'),
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

  describe("What's new for you", () => {
    describe('when not in the candidate variant', () => {
      it('renders WhatsNewForYouMenuItem with help_menu placement (no experiment data)', () => {
        createWrapper();
        const item = findWhatsNewForYouMenuItem();
        expect(item.exists()).toBe(true);
        expect(item.props('placement')).toBe('help_menu');
        expect(item.props('sidebarData')).toBe(sidebarData);
      });

      it('renders the item when explicitly in control variant', () => {
        stubExperiments({ whats_new_placement: 'control' });
        createWrapper();
        expect(findWhatsNewForYouMenuItem().exists()).toBe(true);
      });

      it('fires the render tracking event when the dropdown is opened', () => {
        createWrapper();
        findDropdown().vm.$emit('shown');
        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'render_whats_new_for_you_menu_item',
          expect.objectContaining({ property: 'help_menu' }),
        );
      });
    });

    describe('when in the candidate variant', () => {
      beforeEach(() => {
        stubExperiments({ whats_new_placement: 'candidate' });
        createWrapper();
      });

      it('does not render WhatsNewForYouMenuItem in the help menu', () => {
        expect(findWhatsNewForYouMenuItem().exists()).toBe(false);
      });

      it('does not fire the render tracking event when the dropdown is opened', () => {
        findDropdown().vm.$emit('shown');
        expect(trackingSpy).not.toHaveBeenCalledWith(
          undefined,
          'render_whats_new_for_you_menu_item',
          expect.anything(),
        );
      });
    });

    describe('when display_whats_new is false', () => {
      beforeEach(() => {
        createWrapper({ ...sidebarData, display_whats_new: false });
      });

      it('does not fire the render tracking event when the dropdown is opened', () => {
        findDropdown().vm.$emit('shown');
        expect(trackingSpy).not.toHaveBeenCalledWith(
          undefined,
          'render_whats_new_for_you_menu_item',
          expect.anything(),
        );
      });
    });
  });

  describe('when free_group_upgrade_link is provided', () => {
    beforeEach(() => {
      createWrapper({ ...sidebarData, free_group_upgrade_link: '/groups/my-group/-/billings' });
    });

    it('renders upgrade subscription button', () => {
      expect(findUpgradeButton().exists()).toBe(true);
    });
  });

  describe('when free_group_upgrade_link is not provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render upgrade subscription button', () => {
      expect(findUpgradeButton().exists()).toBe(false);
    });
  });
});
