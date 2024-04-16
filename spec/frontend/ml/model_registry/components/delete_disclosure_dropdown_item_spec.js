import { GlModal, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteDisclosureDropdownItem from '~/ml/model_registry/components/delete_disclosure_dropdown_item.vue';

const MODAL_BODY = 'MODAL_BODY';
const MODAL_TITLE = 'MODAL_TITLE';

describe('DeleteButton', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findModalText = () => wrapper.findByText(MODAL_BODY);

  beforeEach(() => {
    wrapper = shallowMountExtended(DeleteDisclosureDropdownItem, {
      propsData: {
        deleteConfirmationText: MODAL_BODY,
        actionPrimaryText: 'Delete!',
        modalTitle: MODAL_TITLE,
      },
    });
  });

  it('mounts the modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('mounts the button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  describe('when modal is opened', () => {
    it('displays modal title', () => {
      expect(findModal().props('title')).toBe(MODAL_TITLE);
    });

    it('displays modal body', () => {
      expect(findModalText().exists()).toBe(true);
    });

    it('submits the form when primary action is clicked', () => {
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('confirm-deletion').length).toEqual(1);
    });
  });
});
