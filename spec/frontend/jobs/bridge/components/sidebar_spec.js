import { GlButton, GlDropdown } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import BridgeSidebar from '~/jobs/bridge/components/sidebar.vue';
import { BUILD_NAME } from '../mock_data';

describe('Bridge Sidebar', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BridgeSidebar, {
      provide: {
        buildName: BUILD_NAME,
      },
    });
  };

  const findSidebar = () => wrapper.find('aside');
  const findRetryDropdown = () => wrapper.find(GlDropdown);
  const findToggle = () => wrapper.find(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders retry dropdown', () => {
      expect(findRetryDropdown().exists()).toBe(true);
    });
  });

  describe('sidebar expansion', () => {
    beforeEach(() => {
      createComponent();
    });

    it('toggles expansion on button click', async () => {
      expect(findSidebar().classes()).not.toContain('gl-display-none');

      findToggle().vm.$emit('click');
      await nextTick();

      expect(findSidebar().classes()).toContain('gl-display-none');
    });

    describe('on resize', () => {
      it.each`
        breakpoint | isSidebarExpanded
        ${'xs'}    | ${false}
        ${'sm'}    | ${false}
        ${'md'}    | ${true}
        ${'lg'}    | ${true}
        ${'xl'}    | ${true}
      `(
        'sets isSidebarExpanded to `$isSidebarExpanded` when the breakpoint is "$breakpoint"',
        async ({ breakpoint, isSidebarExpanded }) => {
          jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(breakpoint);

          window.dispatchEvent(new Event('resize'));
          await nextTick();

          if (isSidebarExpanded) {
            expect(findSidebar().classes()).not.toContain('gl-display-none');
          } else {
            expect(findSidebar().classes()).toContain('gl-display-none');
          }
        },
      );
    });
  });
});
