import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';

import IssuableSidebarRoot from '~/issuable_sidebar/components/issuable_sidebar_root.vue';

const createComponent = (expanded = true) =>
  shallowMount(IssuableSidebarRoot, {
    propsData: {
      expanded,
    },
    slots: {
      'right-sidebar-items': `
        <button class="js-todo">Todo</button>
      `,
    },
  });

describe('IssuableSidebarRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('watch', () => {
    describe('isExpanded', () => {
      it('emits `sidebar-toggle` event on component', async () => {
        wrapper.setData({
          isExpanded: false,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.emitted('sidebar-toggle')).toBeTruthy();
        expect(wrapper.emitted('sidebar-toggle')[0]).toEqual([
          {
            expanded: false,
          },
        ]);
      });
    });
  });

  describe('methods', () => {
    describe('updatePageContainerClass', () => {
      beforeEach(() => {
        setFixtures('<div class="layout-page"></div>');
      });

      it.each`
        isExpanded | layoutPageClass
        ${true}    | ${'right-sidebar-expanded'}
        ${false}   | ${'right-sidebar-collapsed'}
      `(
        'set class $layoutPageClass to container element when `isExpanded` prop is $isExpanded',
        async ({ isExpanded, layoutPageClass }) => {
          wrapper.setData({
            isExpanded,
          });

          await wrapper.vm.$nextTick();

          wrapper.vm.updatePageContainerClass();

          expect(document.querySelector('.layout-page').classList.contains(layoutPageClass)).toBe(
            true,
          );
        },
      );
    });

    describe('handleWindowResize', () => {
      beforeEach(async () => {
        wrapper.setData({
          userExpanded: true,
        });

        await wrapper.vm.$nextTick();
      });

      it.each`
        breakpoint | isExpandedValue
        ${'xs'}    | ${false}
        ${'sm'}    | ${false}
        ${'md'}    | ${false}
        ${'lg'}    | ${true}
        ${'xl'}    | ${true}
      `(
        'sets `isExpanded` prop to $isExpandedValue only when current screen size is `lg` or `xl`',
        async ({ breakpoint, isExpandedValue }) => {
          jest.spyOn(bp, 'isDesktop').mockReturnValue(breakpoint === 'lg' || breakpoint === 'xl');

          wrapper.vm.handleWindowResize();

          expect(wrapper.vm.isExpanded).toBe(isExpandedValue);
        },
      );

      it('calls `updatePageContainerClass` method', () => {
        jest.spyOn(wrapper.vm, 'updatePageContainerClass');

        wrapper.vm.handleWindowResize();

        expect(wrapper.vm.updatePageContainerClass).toHaveBeenCalled();
      });
    });

    describe('handleToggleSidebarClick', () => {
      beforeEach(async () => {
        jest.spyOn(Cookies, 'set').mockImplementation(jest.fn());
        wrapper.setData({
          isExpanded: true,
        });

        await wrapper.vm.$nextTick();
      });

      it('flips value of `isExpanded`', () => {
        wrapper.vm.handleToggleSidebarClick();

        expect(wrapper.vm.isExpanded).toBe(false);
        expect(wrapper.vm.userExpanded).toBe(false);
      });

      it('updates "collapsed_gutter" cookie value', () => {
        wrapper.vm.handleToggleSidebarClick();

        expect(Cookies.set).toHaveBeenCalledWith('collapsed_gutter', true);
      });

      it('calls `updatePageContainerClass` method', () => {
        jest.spyOn(wrapper.vm, 'updatePageContainerClass');

        wrapper.vm.handleWindowResize();

        expect(wrapper.vm.updatePageContainerClass).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    describe('sidebar expanded', () => {
      beforeEach(async () => {
        wrapper.setData({
          isExpanded: true,
        });

        await wrapper.vm.$nextTick();
      });

      it('renders component container element with class `right-sidebar-expanded` when `isExpanded` prop is true', () => {
        expect(wrapper.classes()).toContain('right-sidebar-expanded');
      });

      it('renders sidebar toggle button with text and icon', () => {
        const buttonEl = wrapper.find('button');

        expect(buttonEl.exists()).toBe(true);
        expect(buttonEl.attributes('title')).toBe('Toggle sidebar');
        expect(buttonEl.find('span').text()).toBe('Collapse sidebar');
        expect(buttonEl.find('[data-testid="icon-collapse"]').isVisible()).toBe(true);
      });
    });

    describe('sidebar collapsed', () => {
      beforeEach(async () => {
        wrapper.setData({
          isExpanded: false,
        });

        await wrapper.vm.$nextTick();
      });

      it('renders component container element with class `right-sidebar-collapsed` when `isExpanded` prop is false', () => {
        expect(wrapper.classes()).toContain('right-sidebar-collapsed');
      });

      it('renders sidebar toggle button with text and icon', () => {
        const buttonEl = wrapper.find('button');

        expect(buttonEl.exists()).toBe(true);
        expect(buttonEl.attributes('title')).toBe('Toggle sidebar');
        expect(buttonEl.find('[data-testid="icon-expand"]').isVisible()).toBe(true);
      });
    });

    it('renders sidebar items', () => {
      const sidebarItemsEl = wrapper.find('[data-testid="sidebar-items"]');

      expect(sidebarItemsEl.exists()).toBe(true);
      expect(sidebarItemsEl.find('button.js-todo').exists()).toBe(true);
    });
  });
});
