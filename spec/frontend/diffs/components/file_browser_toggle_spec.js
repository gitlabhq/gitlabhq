import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { GlAnimatedSidebarIcon, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { keysFor, MR_TOGGLE_FILE_BROWSER } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { Mousetrap } from '~/lib/mousetrap';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { parseBoolean } from '~/lib/utils/common_utils';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');

const hotkeys = keysFor(MR_TOGGLE_FILE_BROWSER);

Vue.use(PiniaVuePlugin);

describe('FileBrowserToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    const pinia = createTestingPinia();
    useFileBrowser();
    wrapper = shallowMount(FileBrowserToggle, {
      pinia,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
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
    expect(toggle.attributes('aria-keyshortcuts')).toBe(hotkeys[0]);
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
    it('toggles visibility on shortcut trigger', () => {
      createComponent();
      Mousetrap.trigger(hotkeys[0]);
      expect(useFileBrowser().toggleFileBrowserVisibility).toHaveBeenCalled();
    });

    it('does not toggle visibility on shortcut trigger after component is destroyed', () => {
      createComponent();
      wrapper.destroy();
      Mousetrap.trigger(hotkeys[0]);
      expect(useFileBrowser().toggleFileBrowserVisibility).not.toHaveBeenCalled();
    });
  });

  describe('tooltip', () => {
    const findTooltip = () => getBinding(findToggle().element, 'gl-tooltip');

    it('Displays hide message for open file browser', () => {
      createComponent();
      expect(findTooltip().value).toBe(
        'Hide file browser <kbd aria-hidden="true" class="flat gl-ml-1">f</kbd>',
      );
    });

    it('Displays show message for hidden file browser', async () => {
      createComponent();
      useFileBrowser().fileBrowserVisible = false;
      await nextTick();
      expect(findTooltip().value).toBe(
        'Show file browser <kbd aria-hidden="true" class="flat gl-ml-1">f</kbd>',
      );
    });
  });
});
