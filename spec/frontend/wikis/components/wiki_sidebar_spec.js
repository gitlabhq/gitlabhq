import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiSidebar from '~/wikis/components/wiki_sidebar.vue';
import WikiSidebarHeader from '~/wikis/components/wiki_sidebar_header.vue';
import WikiSidebarEntries from '~/wikis/components/wiki_sidebar_entries.vue';
import WikiSidebarToggle from '~/wikis/components/wiki_sidebar_toggle.vue';
import { observeSidebarResponsiveness } from '~/wikis/utils/sidebar_responsive';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';

jest.mock('~/wikis/utils/sidebar_responsive');
jest.mock('~/wikis/utils/sidebar_toggle');

describe('WikiSidebar', () => {
  let wrapper;
  let cleanupSpy;

  const findSidebarHeader = () => wrapper.findComponent(WikiSidebarHeader);
  const findSidebarEntries = () => wrapper.findComponent(WikiSidebarEntries);
  const findSidebarToggle = () => wrapper.findComponent(WikiSidebarToggle);

  const createComponent = (provide) => {
    wrapper = shallowMountExtended(WikiSidebar, { provide });
  };

  beforeEach(() => {
    cleanupSpy = jest.fn();
    observeSidebarResponsiveness.mockReturnValue(cleanupSpy);
  });

  describe('responsive sidebar observer', () => {
    beforeEach(() => {
      createComponent({ hasCustomSidebar: false });
    });

    it('sets up the responsive observer on mount', () => {
      expect(observeSidebarResponsiveness).toHaveBeenCalledWith(expect.any(Function));
    });

    it('calls toggleWikiSidebar without persisting when overlap is detected', () => {
      const onAutoClose = observeSidebarResponsiveness.mock.calls[0][0];
      onAutoClose();

      expect(toggleWikiSidebar).toHaveBeenCalledWith(false);
    });

    it('cleans up the observer on destroy', () => {
      wrapper.destroy();

      expect(cleanupSpy).toHaveBeenCalled();
    });
  });

  describe('without custom sidebar', () => {
    beforeEach(() => {
      createComponent({ hasCustomSidebar: false });
    });

    it('renders without error', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('has an aria label', () => {
      expect(wrapper.attributes('aria-label')).toBe('Wiki');
    });

    it('renders the resizer', () => {
      expect(wrapper.find('.js-wiki-sidebar-resizer').exists()).toBe(true);
    });

    it('renders the wiki sidebar header', () => {
      expect(findSidebarHeader().exists()).toBe(true);
    });

    it('renders the wiki sidebar entries', () => {
      expect(findSidebarEntries().exists()).toBe(true);
    });

    it('passes the pages list expanded state to header and entries', async () => {
      expect(findSidebarHeader().props('pagesListExpanded')).toBe(true);
      expect(findSidebarEntries().props('pagesListExpanded')).toBe(true);

      findSidebarHeader().vm.$emit('toggle-pages-list');
      await nextTick();

      expect(findSidebarHeader().props('pagesListExpanded')).toBe(false);
      expect(findSidebarEntries().props('pagesListExpanded')).toBe(false);
    });
  });

  describe('with custom sidebar', () => {
    beforeEach(() => {
      createComponent({ hasCustomSidebar: true });
    });

    it('passes pages list expanded = false by default', () => {
      expect(findSidebarHeader().props('pagesListExpanded')).toBe(false);
      expect(findSidebarEntries().props('pagesListExpanded')).toBe(false);
    });
  });

  describe('with wikiFloatingSidebarToggle feature flag disabled', () => {
    beforeEach(() => {
      createComponent({
        hasCustomSidebar: false,
        glFeatures: { wikiFloatingSidebarToggle: false },
      });
    });

    it('does not show the toggle component', () => {
      expect(findSidebarToggle().exists()).toBe(false);
    });
  });

  describe('with wikiFloatingSidebarToggle feature flag enabled', () => {
    beforeEach(() => {
      createComponent({
        hasCustomSidebar: false,
        glFeatures: { wikiFloatingSidebarToggle: true },
      });
    });

    it('shows the toggle component', () => {
      expect(findSidebarToggle().exists()).toBe(true);
      expect(findSidebarToggle().props('action')).toBe('open');
    });

    it('hides the toggle component on large screens', () => {
      expect(findSidebarToggle().classes()).toContain('gl-hidden');
      expect(findSidebarToggle().classes()).toContain('@lg/panel:gl-block');
    });
  });
});
