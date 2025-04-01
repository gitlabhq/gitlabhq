import { nextTick } from 'vue';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import PermalinkDropdownItem from '~/repository/components/header_area/permalink_dropdown_item.vue';
import { keysFor, PROJECT_FILES_GO_TO_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { Mousetrap } from '~/lib/mousetrap';
import { lineState } from '~/blob/state';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');
jest.mock('~/blob/state');

const relativePermalinkPath =
  'flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json';

describe('PermalinkDropdownItem', () => {
  let wrapper;

  const mockToastShow = jest.fn();

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PermalinkDropdownItem, {
      propsData: {
        permalinkPath: relativePermalinkPath,
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findPermalinkLinkDropdown = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    lineState.currentLineNumber = null;
    createComponent();
  });

  it('renders correctly', () => {
    expect(findPermalinkLinkDropdown().exists()).toBe(true);
  });

  describe('updatedPermalinkPath', () => {
    it('returns absolutePermalinkPath when no line number is set', () => {
      expect(findPermalinkLinkDropdown().attributes('data-clipboard-text')).toBe(
        'http://test.host/flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json',
      );
    });

    it('returns updated path with line number when set', () => {
      lineState.currentLineNumber = '10';
      createComponent();

      expect(findPermalinkLinkDropdown().attributes('data-clipboard-text')).toBe(
        `http://test.host/flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json#L10`,
      );
    });
  });

  describe('handles onCopyPermalink correctly', () => {
    it('shows toast when dropdown item is clicked', async () => {
      findPermalinkLinkDropdown().vm.$emit('action');
      await nextTick();

      expect(mockToastShow).toHaveBeenCalledWith('Permalink copied to clipboard.');
    });

    it('triggers copy permalink when shortcut is used', async () => {
      const clickSpy = jest.spyOn(findPermalinkLinkDropdown().element, 'click');

      Mousetrap.trigger('y');
      await nextTick();

      expect(clickSpy).toHaveBeenCalled();
      expect(mockToastShow).toHaveBeenCalledWith('Permalink copied to clipboard.');
    });
  });

  describe('lifecycle hooks', () => {
    it('binds and unbinds Mousetrap shortcuts', () => {
      const bindSpy = jest.spyOn(Mousetrap, 'bind');
      const unbindSpy = jest.spyOn(Mousetrap, 'unbind');

      createComponent();
      expect(bindSpy).toHaveBeenCalledWith(
        keysFor(PROJECT_FILES_GO_TO_PERMALINK),
        expect.any(Function),
      );

      wrapper.destroy();
      expect(unbindSpy).toHaveBeenCalledWith(keysFor(PROJECT_FILES_GO_TO_PERMALINK));
    });
  });

  it('displays the shortcut key when shortcuts are not disabled', () => {
    shouldDisableShortcuts.mockReturnValue(false);
    createComponent();
    expect(wrapper.find('kbd').exists()).toBe(true);
    expect(wrapper.find('kbd').text()).toBe(keysFor(PROJECT_FILES_GO_TO_PERMALINK)[0]);
  });

  it('does not display the shortcut key when shortcuts are disabled', () => {
    shouldDisableShortcuts.mockReturnValue(true);
    createComponent();
    expect(wrapper.find('kbd').exists()).toBe(false);
  });
});
