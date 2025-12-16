import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiSidebarHeader from '~/wikis/components/wiki_sidebar_header.vue';

describe('WikiSidebar', () => {
  let wrapper;

  const defaultProps = {};
  const defaultProvide = {
    hasCustomSidebar: false,
    hasWikiPages: false,
    editSidebarUrl: '/gitlab-test/-/wikis/_sidebar/edit',
    canCreate: false,
    isEditingSidebar: false,
  };

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMountExtended(WikiSidebarHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  describe('default rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders without error', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('displays the title', () => {
      expect(wrapper.text()).toContain('Wiki Pages');
    });

    it('does not show the pages list toggle', () => {
      expect(wrapper.findByTestId('expand-pages-list').exists()).toBe(false);
    });

    it('does not emit a toggle event when the title is clicked', () => {
      wrapper.findByTestId('wiki-sidebar-title').trigger('click');

      expect(wrapper.emitted('toggle-pages-list')).toBeUndefined();
    });
  });

  describe('custom sidebar', () => {
    describe('default state', () => {
      beforeEach(() => {
        createComponent(
          {},
          {
            hasCustomSidebar: true,
          },
        );
      });

      it('shows the pages list toggle', () => {
        expect(wrapper.findByTestId('expand-pages-list').exists()).toBe(true);
      });

      it('shows the pages list toggle with chevron-right icon', () => {
        expect(wrapper.findByTestId('expand-pages-list').props('icon')).toBe('chevron-right');
      });

      it('emits the toggle event when the pages list toggle is clicked', () => {
        wrapper.findByTestId('expand-pages-list').trigger('click');

        expect(wrapper.emitted('toggle-pages-list')).toHaveLength(1);
      });

      it('emits the toggle event when the title is clicked', () => {
        wrapper.findByTestId('wiki-sidebar-title').trigger('click');

        expect(wrapper.emitted('toggle-pages-list')).toHaveLength(1);
      });
    });

    describe('expanded state', () => {
      beforeEach(async () => {
        createComponent({ pagesListExpanded: true }, { hasCustomSidebar: true });
        await nextTick();
      });

      it('shows the pages list toggle with chevron-down icon', () => {
        expect(wrapper.findByTestId('expand-pages-list').props('icon')).toBe('chevron-down');
      });
    });

    describe('when the user has edit permissions', () => {
      it('shows the create sidebar button', () => {
        createComponent({}, { hasCustomSidebar: false, canCreate: true });

        expect(wrapper.findByTestId('edit-wiki-sidebar-button').exists()).toBe(true);
        expect(wrapper.findByTestId('edit-wiki-sidebar-button').props('href')).toBe(
          '/gitlab-test/-/wikis/_sidebar/edit',
        );
        expect(wrapper.findByTestId('edit-wiki-sidebar-button').attributes('aria-label')).toBe(
          'Add custom sidebar',
        );
        expect(wrapper.findByTestId('edit-wiki-sidebar-button').attributes('title')).toBe(
          'Add custom sidebar',
        );
      });

      it('shows the edit sidebar button', () => {
        createComponent({}, { hasCustomSidebar: true, canCreate: true });

        expect(wrapper.findByTestId('edit-wiki-sidebar-button').exists()).toBe(true);
        expect(wrapper.findByTestId('edit-wiki-sidebar-button').props('href')).toBe(
          '/gitlab-test/-/wikis/_sidebar/edit',
        );
        expect(wrapper.findByTestId('edit-wiki-sidebar-button').attributes('aria-label')).toBe(
          'Edit custom sidebar',
        );
        expect(wrapper.findByTestId('edit-wiki-sidebar-button').attributes('title')).toBe(
          'Edit custom sidebar',
        );
      });
    });
  });
});
