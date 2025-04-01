import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import BlobRepositoryActionsGroup from '~/repository/components/header_area/blob_repository_actions_group.vue';
import PermalinkDropdownItem from '~/repository/components/header_area/permalink_dropdown_item.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { keysFor, START_SEARCH_PROJECT_FILE } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { blobControlsDataMock } from 'ee_else_ce_jest/repository/mock_data';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');
jest.mock('~/blob/state');

const relativePermalinkPath =
  'flightjs/Flight/-/blob/46ca9ebd5a43ec240ee8d64e2bb829169dff744e/bower.json';

describe('BlobRepositoryActionsGroup', () => {
  let wrapper;

  const createComponent = (provided = {}) => {
    wrapper = shallowMountExtended(BlobRepositoryActionsGroup, {
      propsData: {
        permalinkPath: relativePermalinkPath,
      },
      provide: {
        blobInfo: blobControlsDataMock.repository.blobs.nodes[0],
        ...provided,
      },
      stubs: {
        GlDisclosureDropdownGroup,
        PermalinkDropdownItem,
      },
    });
  };

  const findDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findFindFileDropdownItem = () => wrapper.findByTestId('find');
  const findBlameDropdownItem = () => wrapper.findByTestId('blame-dropdown-item');
  const findPermalinkLinkDropdown = () => wrapper.findComponent(PermalinkDropdownItem);
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  beforeEach(() => {
    createComponent();
  });

  it('renders correctly', () => {
    expect(findDropdownGroup().exists()).toBe(true);
    expect(findFindFileDropdownItem().exists()).toBe(true);
    expect(findBlameDropdownItem().exists()).toBe(true);
    expect(findPermalinkLinkDropdown().exists()).toBe(true);
  });

  describe('Find file dropdown item', () => {
    it('renders only on mobile layout', () => {
      expect(findFindFileDropdownItem().classes()).toContain('sm:gl-hidden');
    });

    it('triggers a `focusSearchFile` shortcut when the findFile button is clicked', () => {
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();
      findFindFileDropdownItem().vm.$emit('action');

      expect(Shortcuts.focusSearchFile).toHaveBeenCalled();
    });

    it('emits a tracking event when the Find file button is clicked', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();

      findFindFileDropdownItem().vm.$emit('action');

      expect(trackEventSpy).toHaveBeenCalledWith('click_find_file_button_on_repository_pages');
    });
  });

  describe('Blame dropdown item', () => {
    it('renders only on mobile layout', () => {
      expect(findBlameDropdownItem().classes()).toContain('sm:gl-hidden');
    });

    it('does not render for lfs files', () => {
      createComponent({
        blobInfo: {
          ...blobControlsDataMock.repository.blobs.nodes[0],
          storedExternally: true,
          externalStorage: 'lfs',
        },
      });

      expect(findBlameDropdownItem().exists()).toBe(false);
    });
  });

  it('displays the shortcut key when shortcuts are not disabled', () => {
    shouldDisableShortcuts.mockReturnValue(false);
    createComponent();
    expect(findFindFileDropdownItem().find('kbd').exists()).toBe(true);
    expect(findFindFileDropdownItem().find('kbd').text()).toBe(
      keysFor(START_SEARCH_PROJECT_FILE)[0],
    );
  });

  it('does not display the shortcut key when shortcuts are disabled', () => {
    shouldDisableShortcuts.mockReturnValue(true);
    createComponent();
    expect(findFindFileDropdownItem().find('kbd').exists()).toBe(false);
  });
});
