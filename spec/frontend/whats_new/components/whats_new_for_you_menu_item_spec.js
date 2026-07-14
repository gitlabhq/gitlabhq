import { GlBadge, GlDisclosureDropdownGroup, GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import toggleWhatsNewDrawer from '~/whats_new';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WhatsNewForYouMenuItem from '~/whats_new/components/whats_new_for_you_menu_item.vue';

jest.mock('~/whats_new');

const baseSidebarData = {
  display_whats_new: true,
  whats_new_version_digest: 'v1',
  whats_new_read_articles: [1],
  whats_new_mark_as_read_path: '/mark_as_read',
  whats_new_most_recent_release_items_count: 5,
};

describe('WhatsNewForYouMenuItem', () => {
  let wrapper;

  const createWrapper = ({ sidebarData = baseSidebarData, placement = 'help_menu', icon } = {}) => {
    wrapper = mountExtended(WhatsNewForYouMenuItem, {
      propsData: { sidebarData, placement, icon },
    });
  };

  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findBadge = () => wrapper.findByTestId('whats-new-info-badge');
  const findIcon = () => wrapper.findComponent(GlIcon);

  describe('rendering', () => {
    it('renders the dropdown group when display_whats_new is true', () => {
      createWrapper();
      expect(findGroup().exists()).toBe(true);
    });

    it('does not render anything when display_whats_new is false', () => {
      createWrapper({ sidebarData: { ...baseSidebarData, display_whats_new: false } });
      expect(findGroup().exists()).toBe(false);
    });

    it('uses a placement-specific data-testid', () => {
      createWrapper({ placement: 'profile_menu' });
      expect(wrapper.findByTestId('whats-new-for-you-profile-menu-item').exists()).toBe(true);
    });

    it('renders the icon when the prop is provided', () => {
      createWrapper({ placement: 'profile_menu', icon: 'compass' });
      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props('name')).toBe('compass');
    });

    it('does not render an icon when the prop is omitted', () => {
      createWrapper({ placement: 'help_menu' });
      expect(findIcon().exists()).toBe(false);
    });

    it('sets the click tracking attributes via extraAttrs', () => {
      createWrapper({ placement: 'profile_menu' });
      expect(wrapper.find('[data-track-action="click_whats_new_for_you_menu_item"]').exists()).toBe(
        true,
      );
      expect(wrapper.find('[data-track-property="profile_menu"]').exists()).toBe(true);
      expect(wrapper.find('[data-track-experiment="whats_new_placement"]').exists()).toBe(true);
    });
  });

  describe('unread badge', () => {
    it('renders the badge with the seeded count when there are unread articles', () => {
      createWrapper();
      // 5 total - 1 read = 4
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().text()).toBe('4');
      expect(findBadge().findComponent(GlBadge).props('variant')).toBe('info');
    });

    it('does not render the badge when all articles are read', () => {
      createWrapper({
        sidebarData: {
          ...baseSidebarData,
          whats_new_read_articles: [1, 2, 3, 4, 5],
        },
      });
      expect(findBadge().exists()).toBe(false);
    });

    it('floors negative counts to 0 (no badge)', () => {
      createWrapper({
        sidebarData: {
          ...baseSidebarData,
          whats_new_most_recent_release_items_count: 1,
          whats_new_read_articles: [1, 2, 3],
        },
      });
      expect(findBadge().exists()).toBe(false);
    });
  });

  describe('opening the drawer', () => {
    it('lazy-loads the drawer module and calls it with the sidebar payload + placement', async () => {
      createWrapper({ placement: 'profile_menu' });

      wrapper.findByTestId('whats-new-for-you-profile-menu-item').vm.$emit('action');
      await waitForPromises();

      expect(toggleWhatsNewDrawer).toHaveBeenCalledWith(
        {
          versionDigest: 'v1',
          initialReadArticles: [1],
          markAsReadPath: '/mark_as_read',
          mostRecentReleaseItemsCount: 5,
          placement: 'profile_menu',
        },
        expect.any(Function),
      );
    });

    it('reuses the cached toggle on subsequent clicks (passes no arguments)', async () => {
      createWrapper();
      const item = wrapper.findByTestId('whats-new-for-you-help-menu-item');

      item.vm.$emit('action');
      await waitForPromises();
      item.vm.$emit('action');
      await waitForPromises();

      expect(toggleWhatsNewDrawer).toHaveBeenCalledTimes(2);
      expect(toggleWhatsNewDrawer).toHaveBeenLastCalledWith();
    });

    it('updates the unread count when the drawer reports articles read', async () => {
      createWrapper();
      wrapper.findByTestId('whats-new-for-you-help-menu-item').vm.$emit('action');
      await waitForPromises();

      const [, updateBadge] = toggleWhatsNewDrawer.mock.calls[0];
      updateBadge(0);
      await nextTick();

      expect(findBadge().exists()).toBe(false);
    });
  });
});
