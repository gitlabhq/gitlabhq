import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiSidebar from '~/wikis/components/wiki_sidebar.vue';
import WikiSidebarHeader from '~/wikis/components/wiki_sidebar_header.vue';
import WikiSidebarEntries from '~/wikis/components/wiki_sidebar_entries.vue';

describe('WikiSidebar', () => {
  let wrapper;

  const findSidebarHeader = () => wrapper.findComponent(WikiSidebarHeader);
  const findSidebarEntries = () => wrapper.findComponent(WikiSidebarEntries);

  const createComponent = (provide) => {
    wrapper = shallowMountExtended(WikiSidebar, { provide });
  };

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
});
