import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlTooltip } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import FileTreeBrowserToggle from '~/repository/file_tree_browser/components/file_tree_browser_toggle.vue';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');

Vue.use(PiniaVuePlugin);

describe('FileTreeBrowserToggle', () => {
  let wrapper;
  let pinia;
  let fileTreeBrowserStore;

  const findToggleButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(FileTreeBrowserToggle, { pinia });
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
      fileTreeBrowserStore.setFileTreeVisibility(false);
      createComponent();

      expect(findToggleButton().attributes('aria-label')).toBe('Show file tree browser');
    });

    it('shows "Hide file tree browser" when file tree is visible', () => {
      fileTreeBrowserStore.setFileTreeVisibility(true);
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
      useFileTreeBrowserVisibility().toggleFileTreeVisibility = mockToggle;

      await findToggleButton().vm.$emit('click');

      expect(mockToggle).toHaveBeenCalled();
    });
  });
  describe('tooltip', () => {
    const findTooltip = () => wrapper.findComponent(GlTooltip);
    const findShortcut = () => wrapper.findComponent(Shortcut);

    it('displays hide message for open file browser with shortcut', () => {
      shouldDisableShortcuts.mockReturnValue(false);
      fileTreeBrowserStore.setFileTreeVisibility(true);
      createComponent();
      expect(findTooltip().text()).toContain('Hide file tree browser');
      expect(findShortcut().exists()).toBe(true);
    });

    it('displays show message for hidden file browser with shortcut', async () => {
      shouldDisableShortcuts.mockReturnValue(false);
      createComponent();
      useFileBrowser().fileBrowserVisible = false;
      await nextTick();
      expect(findTooltip().text()).toContain('Show file tree browser');
      expect(findShortcut().exists()).toBe(true);
    });

    it('displays hide message for open file browser without shortcut', () => {
      shouldDisableShortcuts.mockReturnValue(true);
      fileTreeBrowserStore.setFileTreeVisibility(true);
      createComponent();
      expect(findTooltip().text()).toContain('Hide file tree browser');
      expect(findShortcut().exists()).toBe(false);
    });

    it('displays show message for hidden file browser without shortcut', async () => {
      shouldDisableShortcuts.mockReturnValue(true);
      createComponent();
      useFileBrowser().fileBrowserVisible = false;
      await nextTick();
      expect(findTooltip().text()).toContain('Show file tree browser');
      expect(findShortcut().exists()).toBe(false);
    });
  });
});
