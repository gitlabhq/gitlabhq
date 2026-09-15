import { shallowMount, mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { GlAnimatedSidebarIcon, GlButton, GlTooltip } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import {
  keysFor,
  MR_TOGGLE_FILE_BROWSER,
  MR_FOCUS_FILE_BROWSER,
} from '~/behaviors/shortcuts/keybindings';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { Mousetrap } from '~/lib/mousetrap';
import { parseBoolean } from '~/lib/utils/common_utils';

jest.mock('~/behaviors/shortcuts/shortcuts_disabled');

const toggleHotkeys = keysFor(MR_TOGGLE_FILE_BROWSER);
const focusHotkeys = keysFor(MR_FOCUS_FILE_BROWSER);

Vue.use(PiniaVuePlugin);

describe('FileBrowserToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlButton);

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    const pinia = createTestingPinia();
    useFileBrowser();
    wrapper = mountFn(FileBrowserToggle, {
      pinia,
    });
  };

  beforeEach(() => {
    keyboardShortcutsDisabled.mockReturnValue(false);
  });

  it('sets initial browser visibility', () => {
    createComponent();
    expect(useFileBrowser().initFileBrowserVisibility).toHaveBeenCalled();
  });

  it('shows toggle button', () => {
    createComponent();
    const toggle = findToggle();
    expect(toggle.exists()).toBe(true);
    expect(toggle.props('variant')).toBe('default');
    expect(toggle.props('selected')).toBe(true);
    expect(toggle.attributes('data-testid')).toBe('file-tree-button');
    expect(toggle.attributes('aria-label')).toBe('Hide file browser');
    expect(toggle.attributes('aria-keyshortcuts')).toBe(toggleHotkeys[0]);
    const icon = toggle.findComponent(GlAnimatedSidebarIcon);
    expect(icon.exists()).toBe(true);
    // Vue compat doesn't know about component props if it extends other component
    expect(icon.props('isOn') ?? parseBoolean(icon.attributes('is-on'))).toBe(true);
  });

  it('shows toggle button when browser is hidden', async () => {
    createComponent();
    useFileBrowser().fileBrowserVisible = false;
    await nextTick();

    const toggle = findToggle();
    expect(toggle.exists()).toBe(true);
    expect(toggle.props('variant')).toBe('default');
    expect(toggle.props('selected')).toBe(false);
    expect(toggle.attributes('aria-label')).toBe('Show file browser');
    const icon = toggle.findComponent(GlAnimatedSidebarIcon);
    expect(icon.exists()).toBe(true);
    // Vue compat doesn't know about component props if it extends other component
    expect(icon.props('isOn') ?? parseBoolean(icon.attributes('is-on'))).toBe(false);
  });

  it('toggles visibility', () => {
    createComponent();
    findToggle().vm.$emit('click');
    expect(useFileBrowser().toggleFileBrowserVisibility).toHaveBeenCalled();
  });

  describe('shortcuts', () => {
    describe('toggle visibility', () => {
      it('toggles visibility on shortcut trigger', () => {
        createComponent();
        Mousetrap.trigger(toggleHotkeys[0]);
        expect(useFileBrowser().toggleFileBrowserVisibility).toHaveBeenCalled();
      });

      it('does not toggle visibility on shortcut trigger after component is destroyed', () => {
        createComponent();
        wrapper.destroy();
        Mousetrap.trigger(toggleHotkeys[0]);
        expect(useFileBrowser().toggleFileBrowserVisibility).not.toHaveBeenCalled();
      });
    });

    describe('focus', () => {
      it('requests search focus on shortcut trigger', () => {
        createComponent();
        Mousetrap.trigger(focusHotkeys[0]);
        expect(useFileBrowser().setFileBrowserVisibility).toHaveBeenCalledWith(true);
        expect(useFileBrowser().requestSearchFocus).toHaveBeenCalled();
      });

      it('does not focus on shortcut trigger after component is destroyed', () => {
        createComponent();
        wrapper.destroy();
        Mousetrap.trigger(focusHotkeys[0]);
        expect(useFileBrowser().requestSearchFocus).not.toHaveBeenCalled();
      });
    });
  });

  describe('tooltip', () => {
    const findTooltip = () => wrapper.findComponent(GlTooltip);

    it('renders tooltip component', () => {
      createComponent();
      expect(findTooltip().exists()).toBe(true);
    });

    it('displays hide message for open file browser', () => {
      createComponent({ mountFn: mount });
      expect(findTooltip().text()).toContain('Hide file browser');
    });

    it('displays show message for hidden file browser', async () => {
      createComponent({ mountFn: mount });
      useFileBrowser().fileBrowserVisible = false;
      await nextTick();
      expect(findTooltip().text()).toContain('Show file browser');
    });

    it('displays keyboard shortcut when shortcuts are enabled', () => {
      createComponent({ mountFn: mount });
      expect(findTooltip().find('kbd').exists()).toBe(true);
    });

    it('does not display keyboard shortcut when shortcuts are disabled', () => {
      keyboardShortcutsDisabled.mockReturnValue(true);
      createComponent({ mountFn: mount });
      expect(findTooltip().find('kbd').exists()).toBe(false);
    });
  });
});
