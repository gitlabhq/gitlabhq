import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import TreeList from '~/diffs/components/tree_list.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { getCookie, removeCookie, setCookie } from '~/lib/utils/common_utils';
import { TREE_LIST_WIDTH_STORAGE_KEY } from '~/diffs/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import * as types from '~/diffs/store/mutation_types';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(PiniaVuePlugin);

describe('DiffsFileTree', () => {
  let pinia;
  let wrapper;
  let breakpointChangeCallback;
  let mockBreakpointSize;

  useLocalStorageSpy();

  const createComponent = (propsData = {}) => {
    wrapper = extendedWrapper(
      shallowMount(DiffsFileTree, {
        pinia,
        propsData,
      }),
    );
  };

  const mockBreakpointInstance = (breakpointSize = 'lg') => {
    mockBreakpointSize = breakpointSize;

    jest.spyOn(PanelBreakpointInstance, 'isBreakpointDown').mockImplementation((bp) => {
      const breakpoints = ['xl', 'lg', 'md', 'sm', 'xs'];
      const currentIndex = breakpoints.indexOf(mockBreakpointSize);
      const targetIndex = breakpoints.indexOf(bp);
      return currentIndex >= targetIndex;
    });

    jest.spyOn(PanelBreakpointInstance, 'addBreakpointListener').mockImplementation((callback) => {
      breakpointChangeCallback = callback;
    });

    jest.spyOn(PanelBreakpointInstance, 'removeBreakpointListener');
  };

  const triggerBreakpointChange = (newBreakpoint) => {
    mockBreakpointSize = newBreakpoint;
    breakpointChangeCallback(newBreakpoint);
  };

  beforeAll(() => {
    global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = 100;
  });

  afterAll(() => {
    global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
  });

  beforeEach(() => {
    pinia = createTestingPinia();
    useLegacyDiffs();
    mockBreakpointInstance('lg');
  });

  it('renders inside file browser height', () => {
    createComponent();
    expect(wrapper.findComponent(FileBrowserHeight).exists()).toBe(true);
  });

  it('re-emits clickFile event', () => {
    const obj = {};
    createComponent();
    wrapper.findComponent(TreeList).vm.$emit('clickFile', obj);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[obj]]);
  });

  it('re-emits toggleFolder event', () => {
    const obj = {};
    createComponent();
    wrapper.findComponent(TreeList).vm.$emit('toggleFolder', obj);
    expect(wrapper.emitted('toggleFolder')).toStrictEqual([[obj]]);
  });

  it('sets current file on click', () => {
    const file = { fileHash: 'foo' };
    createComponent();
    wrapper.findComponent(TreeList).vm.$emit('clickFile', file);
    expect(useLegacyDiffs()[types.SET_CURRENT_DIFF_FILE]).toHaveBeenCalledWith(file.fileHash);
  });

  describe('size', () => {
    const checkWidth = (width) => {
      expect(wrapper.element.style.width).toEqual(`${width}px`);
      expect(wrapper.findComponent(PanelResizer).props('startSize')).toEqual(width);
    };

    afterEach(() => {
      localStorage.removeItem('mr_tree_list_width');
    });

    describe('when no localStorage record is set', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets initial width when no localStorage has been set', () => {
        checkWidth(320);
      });
    });

    it('sets initial width to localStorage size', () => {
      localStorage.setItem('mr_tree_list_width', '200');
      createComponent();
      checkWidth(200);
    });

    it('updates width', async () => {
      const WIDTH = 500;
      createComponent();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', WIDTH);
      await nextTick();
      checkWidth(WIDTH);
    });

    it('passes down hideFileStats as true when width is less than 260', async () => {
      createComponent();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 200);
      await nextTick();
      expect(wrapper.findComponent(TreeList).props('hideFileStats')).toBe(true);
    });

    it('passes down hideFileStats as false when width is bigger than 260', async () => {
      createComponent();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 300);
      await nextTick();
      expect(wrapper.findComponent(TreeList).props('hideFileStats')).toBe(false);
    });

    describe('persistence', () => {
      beforeEach(() => {
        removeCookie(TREE_LIST_WIDTH_STORAGE_KEY);
        window.localStorage.clear();
      });

      it('recovers width value from cookies', () => {
        setCookie(TREE_LIST_WIDTH_STORAGE_KEY, '250');
        createComponent();
        checkWidth(250);
      });

      it('recovers width value from local storage', () => {
        window.localStorage.setItem(TREE_LIST_WIDTH_STORAGE_KEY, '260');
        createComponent();
        checkWidth(260);
      });

      it('stores width value in cookies', async () => {
        createComponent();
        wrapper.findComponent(PanelResizer).vm.$emit('resize-end', 350);
        await nextTick();
        expect(getCookie(TREE_LIST_WIDTH_STORAGE_KEY)).toBe('350');
      });
    });
  });

  describe('floating resize', () => {
    const getRootStyle = () =>
      window.getComputedStyle(wrapper.findByTestId('file-browser-tree').element);
    const getWrapperStyle = () =>
      window.getComputedStyle(wrapper.findByTestId('file-browser-floating-wrapper').element);

    it('applies cached sizings on resize start', async () => {
      jest.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(() => ({
        height: 200,
        top: 100,
      }));
      createComponent({ floatingResize: true });
      wrapper.findComponent(PanelResizer).vm.$emit('resize-start');
      await nextTick();
      const style = getWrapperStyle();
      expect(style.height).toBe('200px');
      expect(style.width).toBe('350px');
      expect(style.top).toBe('100px');
    });

    it('resizes wrapper element', async () => {
      createComponent({ floatingResize: true });
      wrapper.findComponent(PanelResizer).vm.$emit('resize-start');
      await nextTick();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 140);
      await nextTick();
      const rootStyle = getRootStyle();
      const style = getWrapperStyle();
      expect(rootStyle.width).toBe('350px');
      expect(style.width).toBe('140px');
    });

    it('sets sizings on resize end', async () => {
      createComponent({ floatingResize: true });
      wrapper.findComponent(PanelResizer).vm.$emit('resize-start');
      await nextTick();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 140);
      await nextTick();
      wrapper.findComponent(PanelResizer).vm.$emit('resize-end', 140);
      await nextTick();
      const rootStyle = getRootStyle();
      const style = getWrapperStyle();
      expect(rootStyle.width).toBe('140px');
      expect(style.width).toBe('');
      expect(style.top).toBe('');
    });

    it('sets sizings after timeout', async () => {
      createComponent({ floatingResize: true });
      wrapper.findComponent(PanelResizer).vm.$emit('resize-start');
      await nextTick();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 140);
      await nextTick();
      jest.advanceTimersByTime(100);
      await nextTick();
      const rootStyle = getRootStyle();
      const style = getWrapperStyle();
      expect(rootStyle.width).toBe('140px');
      expect(style.width).toBe('140px');
    });
  });

  it('passes down props to tree list', async () => {
    const groupBlobsListItems = false;
    const loadedFiles = { foo: true };
    const totalFilesCount = '20';
    const rowHeight = 30;
    jest.spyOn(window, 'getComputedStyle').mockReturnValue({
      getPropertyValue() {
        return `${rowHeight}px`;
      },
    });
    createComponent({ loadedFiles, totalFilesCount, groupBlobsListItems });
    await nextTick();
    expect(wrapper.findComponent(TreeList).props('loadedFiles')).toBe(loadedFiles);
    expect(wrapper.findComponent(TreeList).props('totalFilesCount')).toBe(totalFilesCount);
    expect(wrapper.findComponent(TreeList).props('rowHeight')).toBe(rowHeight);
    expect(wrapper.findComponent(TreeList).props('groupBlobsListItems')).toBe(groupBlobsListItems);
  });

  describe('when screen is wide enough', () => {
    beforeEach(() => {
      mockBreakpointInstance('lg');
    });

    it('passes enableStickyHeight as true to FileBrowserHeight', () => {
      createComponent();
      expect(wrapper.findComponent(FileBrowserHeight).props('enableStickyHeight')).toBe(true);
    });

    it('swaps to narrow view when breakpoint changes', async () => {
      createComponent();
      await nextTick();

      triggerBreakpointChange('sm');
      await nextTick();

      expect(wrapper.findComponent(FileBrowserHeight).props('enableStickyHeight')).toBe(false);
    });
  });

  describe('when screen is narrow', () => {
    beforeEach(() => {
      mockBreakpointInstance('sm');
    });

    it('passes enableStickyHeight as false to FileBrowserHeight', async () => {
      createComponent();
      await nextTick();
      expect(wrapper.findComponent(FileBrowserHeight).props('enableStickyHeight')).toBe(false);
    });

    it('swaps to widescreen view when breakpoint changes', async () => {
      createComponent();
      await nextTick();

      triggerBreakpointChange('lg');
      await nextTick();

      expect(wrapper.findComponent(FileBrowserHeight).props('enableStickyHeight')).toBe(true);
    });
  });

  it('unsubscribes from breakpoint changes on destroy', () => {
    mockBreakpointInstance('lg');
    createComponent();

    wrapper.destroy();

    expect(PanelBreakpointInstance.removeBreakpointListener).toHaveBeenCalled();
  });
});
