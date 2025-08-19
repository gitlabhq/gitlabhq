import { shallowMount } from '@vue/test-utils';
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
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { Mousetrap } from '~/lib/mousetrap';
import { parseBoolean } from '~/lib/utils/common_utils';
import { setHTMLFixture } from 'helpers/fixtures';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');

const toggleHotkeys = keysFor(MR_TOGGLE_FILE_BROWSER);
const focusHotkeys = keysFor(MR_FOCUS_FILE_BROWSER);

Vue.use(PiniaVuePlugin);

describe('FileBrowserToggle', () => {
  let wrapper;
  let showToast;

  const findToggle = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    const pinia = createTestingPinia();
    useFileBrowser();
    showToast = jest.fn();
    wrapper = shallowMount(FileBrowserToggle, {
      pinia,
      mocks: {
        $toast: { show: showToast },
      },
    });
  };

  beforeEach(() => {
    shouldDisableShortcuts.mockReturnValue(false);
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
      it('focuses search field on shortcut trigger', async () => {
        setHTMLFixture(`<input id="diff-tree-search">`);
        createComponent();
        Mousetrap.trigger(focusHotkeys[0]);
        await nextTick();
        expect(useFileBrowser().setFileBrowserVisibility).toHaveBeenCalledWith(true);
        expect(document.activeElement).toBe(document.querySelector('#diff-tree-search'));
      });

      it('does not focus on shortcut trigger after component is destroyed', () => {
        createComponent();
        wrapper.destroy();
        Mousetrap.trigger(focusHotkeys[0]);
        expect(useFileBrowser().setFileBrowserVisibility).not.toHaveBeenCalled();
      });
    });
  });

  describe('tooltip', () => {
    const findTooltip = () => wrapper.findComponent(GlTooltip);

    it('displays hide message for open file browser', () => {
      createComponent();
      expect(findTooltip().text()).toContain('Hide file browser');
    });

    it('displays show message for hidden file browser', async () => {
      createComponent();
      useFileBrowser().fileBrowserVisible = false;
      await nextTick();
      expect(findTooltip().text()).toContain('Show file browser');
    });
  });
});
