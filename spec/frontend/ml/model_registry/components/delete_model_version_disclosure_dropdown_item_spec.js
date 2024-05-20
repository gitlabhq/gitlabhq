import { GlModal, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteModelVersionDisclosureDropdownItem from '~/ml/model_registry/components/delete_model_version_disclosure_dropdown_item.vue';

const MODAL_BODY = 'Are you sure you want to delete model version foo?';
const MODAL_TITLE = 'Delete model version?';
const MODAL_CANCEL = 'Cancel';
const MENU_ITEM_TEXT = 'Delete model version';
const VERSION_NAME = 'foo';

describe('DeleteModelVersionDisclosureDropdownItem', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findModalText = () => wrapper.findByText(MODAL_BODY);

  beforeEach(() => {
    wrapper = shallowMountExtended(DeleteModelVersionDisclosureDropdownItem, {
      provide: {
        versionName: VERSION_NAME,
      },
    });
  });

  it('mounts the modal', () => {
    expect(findModal().props()).toMatchObject({
      modalId: 'ml-model-version-delete-modal',
      title: MODAL_TITLE,
      actionPrimary: {
        text: MENU_ITEM_TEXT,
        attributes: { variant: 'danger' },
      },
      actionCancel: {
        text: MODAL_CANCEL,
      },
    });
  });

  it('mounts the button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  it('finds the menu item text', () => {
    expect(wrapper.findByTestId('menu-item-text').text()).toBe(MENU_ITEM_TEXT);
  });

  describe('when modal is opened', () => {
    it('displays modal title', () => {
      expect(findModal().props('title')).toBe(MODAL_TITLE);
    });

    it('displays modal body', () => {
      expect(findModalText().exists()).toBe(true);
    });

    it('emits delete-model-version event when primary action is clicked', () => {
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('delete-model-version').length).toEqual(1);
    });
  });
});
