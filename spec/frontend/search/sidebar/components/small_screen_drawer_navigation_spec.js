import { nextTick } from 'vue';
import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import SmallScreenDrawerNavigation from '~/search/sidebar/components/small_screen_drawer_navigation.vue';

describe('ScopeLegacyNavigation', () => {
  let wrapper;
  let closeSpy;
  let toggleSpy;

  const createComponent = () => {
    wrapper = shallowMountExtended(SmallScreenDrawerNavigation, {
      slots: {
        default: '<div data-testid="default-slot-content">test</div>',
      },
    });
  };

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findTitle = () => wrapper.findComponent('h2');
  const findSlot = () => wrapper.findByTestId('default-slot-content');
  const findDomElementListener = () => wrapper.findComponent(DomElementListener);

  describe('small screen navigation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders drawer', () => {
      expect(findGlDrawer().exists()).toBe(true);
      expect(findGlDrawer().attributes('zindex')).toBe(DRAWER_Z_INDEX.toString());
      expect(findGlDrawer().attributes('headerheight')).toBe('0');
    });

    it('renders title', () => {
      expect(findTitle().exists()).toBe(true);
    });

    it('renders slots', () => {
      expect(findSlot().exists()).toBe(true);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      closeSpy = jest.spyOn(SmallScreenDrawerNavigation.methods, 'closeSmallScreenFilters');
      toggleSpy = jest.spyOn(SmallScreenDrawerNavigation.methods, 'toggleSmallScreenFilters');
      createComponent();
    });

    it('calls onClose', () => {
      findGlDrawer().vm.$emit('close');
      expect(closeSpy).toHaveBeenCalled();
    });

    it('calls toggleSmallScreenFilters', async () => {
      expect(findGlDrawer().props('open')).toBe(false);

      findDomElementListener().vm.$emit('click');
      await nextTick();

      expect(toggleSpy).toHaveBeenCalled();
      expect(findGlDrawer().props('open')).toBe(true);
    });
  });
});
