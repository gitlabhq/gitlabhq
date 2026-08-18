import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameColumnResizer from '~/vue_shared/components/source_viewer/components/blame_column_resizer.vue';
import AccessiblePanelResizer from '~/vue_shared/components/accessible_panel_resizer.vue';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import AccessorUtilities from '~/lib/utils/accessor';
import {
  BLAME_COLUMN_DEFAULT_WIDTH,
  BLAME_COLUMN_MAX_WIDTH,
  BLAME_COLUMN_MIN_WIDTH,
  BLAME_COLUMN_WIDTH_STORAGE_KEY,
} from '~/vue_shared/components/source_viewer/constants';

describe('BlameColumnResizer component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BlameColumnResizer, { propsData: props });
  };

  const findPanelResizer = () => wrapper.findComponent(AccessiblePanelResizer);
  const emittedWidths = () => wrapper.emitted('input')?.flat();
  const lastEmittedWidth = () => emittedWidths().at(-1);

  const setDesktop = (isDesktop) =>
    jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(isDesktop);

  afterEach(() => {
    localStorage.clear();
  });

  describe('on desktop', () => {
    beforeEach(() => setDesktop(true));

    it('renders the drag handle', () => {
      createComponent();

      expect(findPanelResizer().exists()).toBe(true);
    });

    it('passes the current width and bounds to the handle', () => {
      createComponent({ value: 480 });

      expect(findPanelResizer().props()).toMatchObject({
        value: 480,
        defaultSize: BLAME_COLUMN_DEFAULT_WIDTH,
        minSize: BLAME_COLUMN_MIN_WIDTH,
        maxSize: BLAME_COLUMN_MAX_WIDTH,
      });
    });

    it('restores a persisted width on mount', () => {
      localStorage.setItem(BLAME_COLUMN_WIDTH_STORAGE_KEY, '505');
      createComponent();

      expect(lastEmittedWidth()).toBe(505);
    });

    it('falls back to the default width when nothing is persisted', () => {
      createComponent();

      expect(lastEmittedWidth()).toBe(BLAME_COLUMN_DEFAULT_WIDTH);
    });

    it('leaves the current width alone when storage is unavailable', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
      createComponent({ value: 480 });

      expect(wrapper.emitted('input')).toBeUndefined();
    });
  });

  describe('when not on desktop', () => {
    beforeEach(() => setDesktop(false));

    it('does not render the drag handle', () => {
      createComponent();

      expect(findPanelResizer().exists()).toBe(false);
    });

    it('clamps the column to the minimum width', () => {
      localStorage.setItem(BLAME_COLUMN_WIDTH_STORAGE_KEY, '505');
      createComponent();

      expect(lastEmittedWidth()).toBe(BLAME_COLUMN_MIN_WIDTH);
    });
  });

  describe('resizing', () => {
    beforeEach(() => {
      setDesktop(true);
      createComponent();
    });

    it('reports a new width as it is dragged', () => {
      findPanelResizer().vm.$emit('input', 520);

      expect(lastEmittedWidth()).toBe(520);
    });

    it('reports the default width when the handle resets', () => {
      findPanelResizer().vm.$emit('input', null);

      expect(lastEmittedWidth()).toBe(BLAME_COLUMN_DEFAULT_WIDTH);
    });

    it('persists the width once the drag ends', () => {
      findPanelResizer().vm.$emit('resize-end', 600);

      expect(localStorage.getItem(BLAME_COLUMN_WIDTH_STORAGE_KEY)).toBe('600');
    });

    it('does not persist the width when storage is unavailable', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

      findPanelResizer().vm.$emit('resize-end', 600);

      expect(localStorage.getItem(BLAME_COLUMN_WIDTH_STORAGE_KEY)).toBeNull();
    });
  });

  describe('reacting to panel resizes', () => {
    it('clamps to the minimum width when the panel narrows past desktop', async () => {
      setDesktop(true);
      jest.spyOn(PanelBreakpointInstance, 'addResizeListener');
      createComponent();

      expect(findPanelResizer().exists()).toBe(true);

      setDesktop(false);
      PanelBreakpointInstance.addResizeListener.mock.calls[0][0]();
      await nextTick();

      expect(lastEmittedWidth()).toBe(BLAME_COLUMN_MIN_WIDTH);
      expect(findPanelResizer().exists()).toBe(false);
    });

    it('restores the persisted width when the panel widens to desktop', async () => {
      setDesktop(false);
      jest.spyOn(PanelBreakpointInstance, 'addResizeListener');
      createComponent();

      expect(findPanelResizer().exists()).toBe(false);

      localStorage.setItem(BLAME_COLUMN_WIDTH_STORAGE_KEY, '520');
      setDesktop(true);
      PanelBreakpointInstance.addResizeListener.mock.calls[0][0]();
      await nextTick();

      expect(lastEmittedWidth()).toBe(520);
      expect(findPanelResizer().exists()).toBe(true);
    });

    it('stops listening once destroyed', () => {
      jest.spyOn(PanelBreakpointInstance, 'removeResizeListener');
      createComponent();
      const { handlePanelResize } = wrapper.vm;
      wrapper.destroy();

      expect(PanelBreakpointInstance.removeResizeListener).toHaveBeenCalledWith(handlePanelResize);
    });
  });
});
