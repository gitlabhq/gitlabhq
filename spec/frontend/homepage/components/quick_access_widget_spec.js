import { nextTick } from 'vue';
import { GlButtonGroup, GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import QuickAccessWidget from '~/homepage/components/quick_access_widget.vue';
import RecentlyViewedItems from '~/homepage/components/recently_viewed_items.vue';
import ProjectsList from '~/homepage/components/projects_list.vue';

describe('QuickAccessWidget', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(QuickAccessWidget);
  };

  const findRecentlyViewedItemsTab = () =>
    wrapper
      .findComponent(GlButtonGroup)
      .findAllComponents(GlButton)
      .wrappers.find((w) => w.text() === 'Recently viewed');
  const findProjectsTab = () =>
    wrapper
      .findComponent(GlButtonGroup)
      .findAllComponents(GlButton)
      .wrappers.find((w) => w.text() === 'Projects');
  const findRecentlyViewedItems = () => wrapper.findComponent(RecentlyViewedItems);
  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findProjectSourceListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const clickProjectsTab = async () => {
    findProjectsTab().vm.$emit('click');
    await nextTick();
  };

  const clickRecentlyViewedTab = async () => {
    findRecentlyViewedItemsTab().vm.$emit('click');
    await nextTick();
  };

  describe('tab switching', () => {
    beforeEach(() => {
      localStorage.clear();
      createComponent();
    });

    it('shows recently viewed by default', () => {
      expect(findRecentlyViewedItemsTab().props('selected')).toBe(true);
      expect(findRecentlyViewedItems().exists()).toBe(true);
      expect(findProjectsList().exists()).toBe(false);
    });

    it('switches to projects when tab clicked', async () => {
      await clickProjectsTab();

      expect(findProjectsTab().props('selected')).toBe(true);
      expect(findProjectsList().exists()).toBe(true);
      expect(findRecentlyViewedItems().exists()).toBe(false);
    });

    it('switches back to recently viewed', async () => {
      await clickProjectsTab();
      await clickRecentlyViewedTab();

      expect(findRecentlyViewedItemsTab().props('selected')).toBe(true);
      expect(findRecentlyViewedItems().exists()).toBe(true);
    });
  });

  describe('localStorage persistence', () => {
    beforeEach(() => {
      localStorage.clear();
    });

    afterEach(() => {
      if (wrapper) {
        wrapper.destroy();
      }
    });

    it('persists and restores active view', async () => {
      createComponent();
      await clickProjectsTab();

      expect(findProjectsList().exists()).toBe(true);

      wrapper.destroy();
      createComponent();

      expect(findProjectsList().exists()).toBe(true);
    });

    it('defaults to recently viewed for invalid stored view', () => {
      localStorage.setItem('homepage_quick_access_active_view', 'invalid-view');
      createComponent();

      expect(findRecentlyViewedItems().exists()).toBe(true);
    });

    it('persists and restores selected project sources', async () => {
      createComponent();
      await clickProjectsTab();

      const listbox = findProjectSourceListbox();
      listbox.vm.$emit('select', ['STARRED']);
      await nextTick();

      expect(findProjectsList().props('selectedSources')).toEqual(['STARRED']);

      wrapper.destroy();
      createComponent();

      expect(findProjectsList().props('selectedSources')).toEqual(['STARRED']);
    });
  });

  describe('project source filtering', () => {
    beforeEach(() => {
      localStorage.clear();
      createComponent();
    });

    it('shows project source listbox only on projects tab', async () => {
      expect(findProjectSourceListbox().exists()).toBe(false);

      await clickProjectsTab();

      expect(findProjectSourceListbox().exists()).toBe(true);
    });

    it('hides project source listbox on recently viewed tab', async () => {
      await clickProjectsTab();
      expect(findProjectSourceListbox().exists()).toBe(true);

      await clickRecentlyViewedTab();
      expect(findProjectSourceListbox().exists()).toBe(false);
    });

    it('defaults to frecent projects', async () => {
      await clickProjectsTab();

      expect(findProjectsList().props('selectedSources')).toEqual(['FRECENT']);
    });

    it('updates project sources when listbox selection changes', async () => {
      await clickProjectsTab();

      const listbox = findProjectSourceListbox();
      listbox.vm.$emit('select', ['STARRED']);
      await nextTick();

      expect(findProjectsList().props('selectedSources')).toEqual(['STARRED']);
    });

    it('falls back to frecent when all sources are deselected', async () => {
      await clickProjectsTab();

      const listbox = findProjectSourceListbox();
      listbox.vm.$emit('select', []);
      await nextTick();

      expect(findProjectsList().props('selectedSources')).toEqual(['FRECENT']);
    });
  });
});
