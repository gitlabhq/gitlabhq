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

  beforeEach(() => {
    pinia = createTestingPinia({ stubActions: false });
    fileTreeBrowserStore = useFileTreeBrowserVisibility();
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
  describe('tooltip', () => {
    it.each`
      browserState   | shortcutState | expectedTooltipText         | shouldShowShortcut
      ${'expanded'}  | ${'enabled'}  | ${'Hide file tree browser'} | ${true}
      ${'collapsed'} | ${'enabled'}  | ${'Show file tree browser'} | ${true}
      ${'expanded'}  | ${'disabled'} | ${'Hide file tree browser'} | ${false}
      ${'collapsed'} | ${'disabled'} | ${'Show file tree browser'} | ${false}
    `(
      'displays $expectedTooltipText tooltip when browser is $browserState and shortcuts are $shortcutState',
      async ({ browserState, shortcutState, expectedTooltipText, shouldShowShortcut }) => {
        const isExpanded = browserState === 'expanded';
        const areShortcutsDisabled = shortcutState === 'disabled';

        shouldDisableShortcuts.mockReturnValue(areShortcutsDisabled);

        if (isExpanded) {
          fileTreeBrowserStore.setFileTreeBrowserIsExpanded(true);
        }

        createComponent();

        if (!isExpanded) {
          useFileBrowser().fileTreeBrowserIsVisible = false;
          await nextTick();
        }

        expect(findTooltip().text()).toContain(expectedTooltipText);
        expect(findShortcut().exists()).toBe(shouldShowShortcut);
      },
    );
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
    });

    describe('when the localStorage entry is true', () => {
      it('shows the popover', async () => {
        localStorage.setItem('ftb-popover-visible', 'true');
        createComponent();
        await nextTick();

        expect(findPopover().exists()).toBe(true);
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

    describe('when dismissing the popover', () => {
      beforeEach(() => {
        createComponent();
        findPopover().vm.$emit('close-button-clicked');
      });

      it('sets the correct localStorage item', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith('ftb-popover-visible', 'false');
      });

      it('sets the correct localStorage value', () => {
        expect(localStorage.getItem('ftb-popover-visible')).toBe('false');
      });
    });
  });
});
