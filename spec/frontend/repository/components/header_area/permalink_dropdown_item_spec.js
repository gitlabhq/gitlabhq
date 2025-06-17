import { nextTick } from 'vue';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import PermalinkDropdownItem from '~/repository/components/header_area/permalink_dropdown_item.vue';
import { keysFor, PROJECT_FILES_COPY_FILE_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { Mousetrap } from '~/lib/mousetrap';
import { hashState, updateHash } from '~/blob/state';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

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
        source: 'blob',
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
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  beforeEach(() => {
    hashState.currentHash = null;
    createComponent();
  });

  it('renders correctly', () => {
    expect(findPermalinkLinkDropdown().exists()).toBe(true);
  });

  describe('hash change handling', () => {
    it('calls updateHash when hash changes', () => {
      window.location.hash = 'L42';
      createComponent();
      window.dispatchEvent(new Event('hashchange'));

      expect(updateHash).toHaveBeenCalledWith('#L42');
    });

    it('handles empty hash correctly', () => {
      window.location.hash = '';
      createComponent();
      window.dispatchEvent(new Event('hashchange'));

      expect(updateHash).toHaveBeenCalledWith('');
    });
  });

  describe('updatedPermalinkPath', () => {
    it('returns absolutePermalinkPath when no line number is set', () => {
      expect(findPermalinkLinkDropdown().attributes('data-clipboard-text')).toBe(
        'http://test.host/flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json',
      );
    });

    it('returns updated path with line number when set', () => {
      hashState.currentHash = '#L10';
      createComponent();

      expect(findPermalinkLinkDropdown().attributes('data-clipboard-text')).toBe(
        `http://test.host/flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json#L10`,
      );
    });

    it('returns updated path with line number range when set', () => {
      hashState.currentHash = '#L5-10';
      createComponent();

      expect(findPermalinkLinkDropdown().attributes('data-clipboard-text')).toBe(
        `http://test.host/flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json#L5-10`,
      );
    });

    it('returns updated path with anchors when set', () => {
      hashState.currentHash = '#something-wonderful';
      createComponent();

      expect(findPermalinkLinkDropdown().attributes('data-clipboard-text')).toBe(
        `http://test.host/flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json#something-wonderful`,
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

      const mousetrapInstance = wrapper.vm.mousetrap;

      const triggerSpy = jest.spyOn(mousetrapInstance, 'trigger');
      mousetrapInstance.trigger('y');

      await nextTick();

      expect(triggerSpy).toHaveBeenCalledWith('y');
      expect(clickSpy).toHaveBeenCalled();
      expect(mockToastShow).toHaveBeenCalledWith('Permalink copied to clipboard.');
    });

    describe('tracking events', () => {
      it.each([['blob'], ['repository']])(
        'emits a tracking event with %s source when the dropdown item is clicked',
        (source) => {
          createComponent({ source });
          const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
          findPermalinkLinkDropdown().vm.$emit('action');
          expect(trackEventSpy).toHaveBeenCalledWith(
            'click_permalink_button_in_overflow_menu',
            { label: 'click', property: source },
            undefined,
          );
        },
      );

      it.each(['blob', 'repository'])(
        'emits a tracking event with %s source when the shortcut is used',
        async (source) => {
          createComponent({ source });
          const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
          const clickSpy = jest.spyOn(findPermalinkLinkDropdown().element, 'click');

          const mousetrapInstance = wrapper.vm.mousetrap;
          const triggerSpy = jest.spyOn(mousetrapInstance, 'trigger');
          mousetrapInstance.trigger('y');

          await nextTick();

          expect(triggerSpy).toHaveBeenCalledWith('y');
          expect(clickSpy).toHaveBeenCalled();
          expect(trackEventSpy).toHaveBeenCalledWith(
            'click_permalink_button_in_overflow_menu',
            { label: 'shortcut', property: source },
            undefined,
          );
        },
      );
    });
  });

  describe('lifecycle hooks', () => {
    it('binds and unbinds Mousetrap shortcuts', () => {
      const bindSpy = jest.spyOn(Mousetrap.prototype, 'bind');
      const unbindSpy = jest.spyOn(Mousetrap.prototype, 'unbind');

      createComponent();
      expect(bindSpy).toHaveBeenCalledWith(
        keysFor(PROJECT_FILES_COPY_FILE_PERMALINK),
        expect.any(Function),
      );

      wrapper.destroy();
      expect(unbindSpy).toHaveBeenCalledWith(keysFor(PROJECT_FILES_COPY_FILE_PERMALINK));
    });

    it('add and remove event listener for hashChange event', () => {
      const addEventListenerSpy = jest.spyOn(window, 'addEventListener');
      const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');

      createComponent();
      expect(addEventListenerSpy).toHaveBeenCalledWith('hashchange', expect.any(Function));

      wrapper.destroy();
      expect(removeEventListenerSpy).toHaveBeenCalledWith('hashchange', expect.any(Function));
    });
  });

  it('displays the shortcut key when shortcuts are not disabled', () => {
    shouldDisableShortcuts.mockReturnValue(false);
    createComponent();
    expect(wrapper.find('kbd').exists()).toBe(true);
    expect(wrapper.find('kbd').text()).toBe(keysFor(PROJECT_FILES_COPY_FILE_PERMALINK)[0]);
  });

  it('does not display the shortcut key when shortcuts are disabled', () => {
    shouldDisableShortcuts.mockReturnValue(true);
    createComponent();
    expect(wrapper.find('kbd').exists()).toBe(false);
  });
});
