import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import DiffAppControls from '~/diffs/components/diff_app_controls.vue';
import DiffStats from '~/diffs/components/diff_stats.vue';
import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import {
  keysFor,
  MR_COLLAPSE_ALL_FILES,
  MR_EXPAND_ALL_FILES,
} from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';

const DEFAULT_PROPS = {
  diffsCount: '5',
  addedLines: 10,
  removedLines: 5,
  showWhitespace: true,
  diffViewType: 'inline',
  viewDiffsFileByFile: false,
};

describe('DiffAppControls', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffAppControls, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  const findButtonByIcon = (icon) =>
    wrapper
      .findAllComponents(GlButton)
      .filter((buttonWrapper) => buttonWrapper.props('icon') === icon)
      .at(0);

  describe('when has changes', () => {
    beforeEach(() => {
      createComponent({ hasChanges: true });
    });

    it('renders diff stats', () => {
      expect(wrapper.findComponent(DiffStats).exists()).toBe(true);
      expect(wrapper.findComponent(DiffStats).props()).toMatchObject({
        diffsCount: DEFAULT_PROPS.diffsCount,
        addedLines: DEFAULT_PROPS.addedLines,
        removedLines: DEFAULT_PROPS.removedLines,
        hideOnNarrowScreen: true,
      });
    });

    it('renders expand buttons', () => {
      expect(findButtonByIcon('expand').exists()).toBe(true);
      expect(findButtonByIcon('collapse').exists()).toBe(true);
    });

    it('emits expandAllFiles', () => {
      findButtonByIcon('expand').vm.$emit('click');
      expect(wrapper.emitted('expandAllFiles')).toStrictEqual([[]]);
    });

    it('emits expandAllFiles on hotkey', () => {
      Mousetrap.trigger(keysFor(MR_EXPAND_ALL_FILES)[0]);
      expect(wrapper.emitted('expandAllFiles')).toStrictEqual([[]]);
    });

    it('emits collapseAllFiles', () => {
      findButtonByIcon('collapse').vm.$emit('click');
      expect(wrapper.emitted('collapseAllFiles')).toStrictEqual([[]]);
    });

    it('emits collapseAllFiles on hotkey', () => {
      Mousetrap.trigger(keysFor(MR_COLLAPSE_ALL_FILES)[0]);
      expect(wrapper.emitted('collapseAllFiles')).toStrictEqual([[]]);
    });

    it('renders settings', () => {
      expect(wrapper.findComponent(SettingsDropdown).exists()).toBe(true);
    });
  });

  describe('when has no changes', () => {
    beforeEach(() => {
      createComponent({
        hasChanges: false,
        showWhitespace: false,
        diffViewType: 'parallel',
        viewDiffsFileByFile: true,
      });
    });

    it('renders settings', () => {
      expect(wrapper.findComponent(SettingsDropdown).exists()).toBe(true);
      expect(wrapper.findComponent(SettingsDropdown).props()).toStrictEqual({
        showWhitespace: false,
        diffViewType: 'parallel',
        viewDiffsFileByFile: true,
        fileByFileSupported: true,
      });
    });

    it('emits events', () => {
      wrapper.findComponent(SettingsDropdown).vm.$emit('updateDiffViewType');
      wrapper.findComponent(SettingsDropdown).vm.$emit('toggleWhitespace');
      wrapper.findComponent(SettingsDropdown).vm.$emit('toggleFileByFile');
      expect(wrapper.emitted('updateDiffViewType')).toStrictEqual([[undefined]]);
      expect(wrapper.emitted('toggleWhitespace')).toStrictEqual([[undefined]]);
      expect(wrapper.emitted('toggleFileByFile')).toStrictEqual([[undefined]]);
    });
  });

  it('disables expand controls when loading', () => {
    createComponent({
      hasChanges: true,
      isLoading: true,
    });
    expect(findButtonByIcon('expand').props('disabled')).toBe(true);
    expect(findButtonByIcon('collapse').props('disabled')).toBe(true);
  });

  it('disables collapseAllFiles hotkey when loading', () => {
    createComponent({ isLoading: true });
    Mousetrap.trigger(keysFor(MR_COLLAPSE_ALL_FILES)[0]);
    expect(wrapper.emitted('collapseAllFiles')).toBe(undefined);
  });

  it('disables expandAllFiles hotkey when loading', () => {
    createComponent({ isLoading: true });
    Mousetrap.trigger(keysFor(MR_EXPAND_ALL_FILES)[0]);
    expect(wrapper.emitted('expandAllFiles')).toBe(undefined);
  });

  it('hides non-existent diff stats', () => {
    createComponent({ hasChanges: true, diffsCount: '' });
    expect(wrapper.findComponent(DiffStats).exists()).toBe(false);
  });
});
