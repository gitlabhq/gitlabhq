import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlTooltip, GlPopover } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import FileTreeBrowserToggle from '~/repository/file_tree_browser/components/file_tree_browser_toggle.vue';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
  EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
} from '~/repository/constants';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');

Vue.use(PiniaVuePlugin);

describe('FileTreeBrowserToggle', () => {
  let wrapper;
  let pinia;
  let fileTreeBrowserStore;

  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findShortcut = () => wrapper.findComponent(Shortcut);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createComponent = () => {
    wrapper = shallowMount(FileTreeBrowserToggle, {
      pinia,
      stubs: {
        LocalStorageSync,
        GlTooltip,
      },
    });
  };

  // Set up fake timers for entire file to satisfy global test cleanup
  beforeAll(() => {
    jest.useFakeTimers({ legacyFakeTimers: true });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  beforeEach(() => {
    pinia = createTestingPinia({ stubActions: false });
    fileTreeBrowserStore = useFileTreeBrowserVisibility();
  });

  afterEach(() => {
    jest.clearAllTimers();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a button with file-tree icon', () => {
      const button = findToggleButton();

      expect(button.props('icon')).toBe('file-tree');
    });
  });

  describe('button text and aria-label', () => {
    it('shows "Show file tree browser" when file tree is hidden', () => {
      fileTreeBrowserStore.setFileTreeBrowserIsExpanded(false);
      createComponent();

      expect(findToggleButton().attributes('aria-label')).toBe('Show file tree browser');
    });

    it('shows "Hide file tree browser" when file tree is visible', () => {
      fileTreeBrowserStore.setFileTreeBrowserIsExpanded(true);
      createComponent();

      expect(findToggleButton().attributes('aria-label')).toBe('Hide file tree browser');
    });
  });

  describe('toggle functionality', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls toggle method when button is clicked', async () => {
      const mockToggle = jest.fn();
      useFileTreeBrowserVisibility().handleFileTreeBrowserToggleClick = mockToggle;

      await findToggleButton().vm.$emit('click');

      expect(mockToggle).toHaveBeenCalled();
    });

    it('triggers a tracking event when the button is clicked', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      fileTreeBrowserStore.setFileTreeBrowserIsExpanded(false);

      createComponent();
      await findToggleButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
        { label: 'click' },
        undefined,
      );

      await findToggleButton().vm.$emit('click');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
        { label: 'click' },
        undefined,
      );
    });
  });

  describe('focus restoration', () => {
    describe('watcher for shouldRestoreFocusToToggle', () => {
      it('calls restoreToggleFocus when flag becomes true', async () => {
        createComponent();
        const restoreFocusSpy = jest.spyOn(wrapper.vm, 'restoreToggleFocus');

        fileTreeBrowserStore.shouldRestoreFocusToToggle = true;
        await nextTick();
        await nextTick();

        expect(restoreFocusSpy).toHaveBeenCalled();
      });

      it('does not call restoreFocus when flag is false', async () => {
        createComponent();
        const restoreFocusSpy = jest.spyOn(wrapper.vm, 'restoreToggleFocus');

        fileTreeBrowserStore.shouldRestoreFocusToToggle = false;
        await nextTick();

        expect(restoreFocusSpy).not.toHaveBeenCalled();
      });

      it('does not call restoreFocus when flag changes from true to false', async () => {
        fileTreeBrowserStore.shouldRestoreFocusToToggle = true;
        createComponent();
        await nextTick();

        const restoreFocusSpy = jest.spyOn(wrapper.vm, 'restoreToggleFocus');

        fileTreeBrowserStore.shouldRestoreFocusToToggle = false;
        await nextTick();

        expect(restoreFocusSpy).not.toHaveBeenCalled();
      });
    });

    describe('mounted hook', () => {
      it('calls restoreToggleFocus if flag is true', async () => {
        fileTreeBrowserStore.shouldRestoreFocusToToggle = true;

        const restoreFocusSpy = jest.spyOn(FileTreeBrowserToggle.methods, 'restoreToggleFocus');

        createComponent();
        await nextTick();

        expect(restoreFocusSpy).toHaveBeenCalled();
      });

      it('does not call restoreFocus if shouldRestoreFocusToToggle is false', () => {
        fileTreeBrowserStore.shouldRestoreFocusToToggle = false;

        const restoreFocusSpy = jest.spyOn(FileTreeBrowserToggle.methods, 'restoreToggleFocus');

        createComponent();

        expect(restoreFocusSpy).not.toHaveBeenCalled();
      });
    });

    describe('restoreToggleFocus method', () => {
      it('focuses the toggle button', async () => {
        createComponent();
        await nextTick();

        // ✅ GitLab Pattern: Mock the focus method on the ref
        const mockFocus = jest.fn();
        wrapper.vm.$refs.toggle.$el.focus = mockFocus;

        wrapper.vm.restoreToggleFocus();
        await nextTick();

        expect(mockFocus).toHaveBeenCalled();
      });

      it('clears the restore focus flag', async () => {
        createComponent();
        await nextTick();

        const clearFlagSpy = jest.spyOn(wrapper.vm, 'clearRestoreFocusFlag');

        wrapper.vm.restoreToggleFocus();
        await nextTick();

        expect(clearFlagSpy).toHaveBeenCalled();
      });
    });
  });

  describe('tooltip', () => {
    it('displays "Hide file tree browser" tooltip when browser is expanded and shortcuts are enabled', () => {
      shouldDisableShortcuts.mockReturnValue(false);
      fileTreeBrowserStore.setFileTreeBrowserIsExpanded(true);

      createComponent();

      expect(findTooltip().text()).toContain('Hide file tree browser');
      expect(findShortcut().exists()).toBe(true);
    });

    it('displays "Show file tree browser" tooltip when browser is collapsed and shortcuts are enabled', async () => {
      shouldDisableShortcuts.mockReturnValue(false);

      createComponent();

      useFileBrowser().fileTreeBrowserIsVisible = false;
      await nextTick();

      expect(findTooltip().text()).toContain('Show file tree browser');
      expect(findShortcut().exists()).toBe(true);
    });

    it('does not render tooltip when shortcuts are disabled', () => {
      shouldDisableShortcuts.mockReturnValue(true);
      fileTreeBrowserStore.setFileTreeBrowserIsExpanded(true);

      createComponent();

      expect(findShortcut().exists()).toBe(false);
    });
  });

  describe('FileTreeBrowserToggle popover', () => {
    useLocalStorageSpy();

    afterEach(() => {
      localStorage.clear();
    });

    describe('when mounted', () => {
      beforeEach(() => {
        createComponent();
      });

      it('has the correct target', () => {
        expect(findPopover().props('target')).toBe('file-tree-browser-toggle');
      });

      it('has an empty localStorage', () => {
        expect(localStorage.getItem('ftb-popover-visible')).toBe(null);
      });

      it('has empty triggers prop', () => {
        expect(findPopover().props('triggers')).toBe('');
      });

      it('is not shown immediately on mount', () => {
        expect(findPopover().props('show')).toBe(false);
      });

      it('is shown after 500ms delay', async () => {
        jest.advanceTimersByTime(500);
        await nextTick();

        expect(findPopover().props('show')).toBe(true);
      });
    });

    describe('when the localStorage entry is true', () => {
      it('shows the popover after delay', async () => {
        localStorage.setItem('ftb-popover-visible', 'true');
        createComponent();
        await nextTick();

        expect(findPopover().exists()).toBe(true);
        expect(findPopover().props('show')).toBe(false);

        jest.advanceTimersByTime(500);
        await nextTick();

        expect(findPopover().props('show')).toBe(true);
      });
    });

    describe('when the localStorage entry is false', () => {
      it('does not show the popover', async () => {
        localStorage.setItem('ftb-popover-visible', 'false');
        createComponent();
        await nextTick();

        expect(findPopover().exists()).toBe(false);
      });
    });

    describe('when dismissing the popover via close button', () => {
      beforeEach(async () => {
        localStorage.setItem('ftb-popover-visible', 'true');
        createComponent();

        jest.advanceTimersByTime(500);
        await nextTick();

        findPopover().vm.$emit('close-button-clicked');
        await nextTick();
      });

      it('sets the correct localStorage item', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith('ftb-popover-visible', 'false');
      });

      it('sets the correct localStorage value', () => {
        expect(localStorage.getItem('ftb-popover-visible')).toBe('false');
      });

      it('hides the popover', () => {
        expect(findPopover().exists()).toBe(false);
      });
    });

    describe('when dismissing the popover via toggle button click', () => {
      beforeEach(async () => {
        localStorage.setItem('ftb-popover-visible', 'true');
        createComponent();

        jest.advanceTimersByTime(500);
        await nextTick();

        await findToggleButton().vm.$emit('click');
        await nextTick();
      });

      it('sets the correct localStorage item', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith('ftb-popover-visible', 'false');
      });

      it('sets the correct localStorage value', () => {
        expect(localStorage.getItem('ftb-popover-visible')).toBe('false');
      });

      it('hides the popover', () => {
        expect(findPopover().exists()).toBe(false);
      });
    });
  });
});
