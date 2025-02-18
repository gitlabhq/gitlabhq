import { GlLink, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WikiSidebarEntry from '~/pages/shared/wikis/components/wiki_sidebar_entry.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('pages/shared/wikis/components/wiki_sidebar_entry', () => {
  useLocalStorageSpy();

  let wrapper;

  function buildWrapper(props = {}, provide = {}) {
    wrapper = mountExtended(WikiSidebarEntry, {
      propsData: props,
      provide: {
        canCreate: false,
        ...provide,
      },
      stubs: {},
    });
  }

  afterEach(() => {
    localStorage.clear();
  });

  describe('when the page has no children', () => {
    beforeEach(() => {
      buildWrapper({ page: { title: 'Foo', path: '/foo', children: [] } });
    });

    it('renders a link to the page', () => {
      const link = wrapper.findComponent(GlLink);

      expect(link.text()).toBe('Foo');
      expect(link.attributes('href')).toBe('/foo');
    });

    it('does not render any chevrons', () => {
      const chevrons = wrapper.findAllComponents(GlIcon);

      expect(chevrons).toHaveLength(0);
    });

    it('does not show a + button to create a new page if canCreate=false', () => {
      expect(wrapper.findByTestId('wiki-list-create-child-button').exists()).toBe(false);
    });

    it('shows a + button to create a new page if canCreate=true', () => {
      buildWrapper({ page: { title: 'Foo', path: '/foo', children: [] } }, { canCreate: true });

      expect(wrapper.findByTestId('wiki-list-create-child-button').exists()).toBe(true);
    });

    it('highlights the searchTerm in the page title', () => {
      buildWrapper({ page: { title: 'Foo', path: '/foo', children: [] }, searchTerm: 'Fo' });

      expect(wrapper.html()).toContain('<span class="gl-bg-status-warning">Fo</span>o');
    });
  });

  describe('when the page has children', () => {
    const buildWrapperWithChildren = () => {
      buildWrapper({
        page: {
          title: 'Foo',
          path: '/foo',
          children: [
            { title: 'Bar', path: '/foo/bar', children: [] },
            { title: 'Baz', path: '/foo/baz', children: [] },
          ],
        },
      });
    };

    beforeEach(buildWrapperWithChildren);

    it('renders a link to all the pages', () => {
      const links = wrapper.findAllComponents(GlLink);
      const expected = [
        { text: 'Foo', href: '/foo' },
        { text: 'Bar', href: '/foo/bar' },
        { text: 'Baz', href: '/foo/baz' },
      ];

      links.wrappers.forEach((link, i) => {
        expect(link.text()).toBe(expected[i].text);
        expect(link.attributes('href')).toBe(expected[i].href);
      });
    });

    it('renders a chevron icon', () => {
      const chevron = wrapper.findComponent(GlIcon);

      expect(chevron.props('name')).toBe('chevron-down');
    });

    it('collapses the children when the node is clicked', async () => {
      const chevron = wrapper.findComponent(GlIcon);

      await wrapper.findByTestId('wiki-list').trigger('click');

      expect(chevron.props('name')).toBe('chevron-right');
      expect(wrapper.findAllComponents(GlLink)).toHaveLength(1);
    });

    it('stores the value of the collapsed state in local storage', async () => {
      await wrapper.findByTestId('wiki-list').trigger('click');

      expect(localStorage.setItem).toHaveBeenCalledWith('wiki:/foo:collapsed', 'true');

      await wrapper.findByTestId('wiki-list').trigger('click');

      expect(localStorage.setItem).toHaveBeenCalledWith('wiki:/foo:collapsed', 'false');
    });
  });
});
