import { GlModal, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteModelDisclosureDropdownItem from '~/ml/model_registry/components/delete_model_disclosure_dropdown_item.vue';

describe('DeleteButton', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findModalText = () =>
    wrapper.findByText('Are you sure you would like to delete this model?');
  const findNote = () => wrapper.findByTestId('confirmation-note');

  beforeEach(() => {
    wrapper = shallowMountExtended(DeleteModelDisclosureDropdownItem, {
      propsData: {
        model: {
          id: 1,
          name: 'modelName',
        },
      },
    });
  });

  it('mounts the modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('uses unique modal ids', () => {
    expect(findModal().props('modalId')).toBe('ml-models-delete-modal-1');
  });

  it('mounts the button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  describe('when modal is opened', () => {
    it('displays modal title', () => {
      expect(findModal().props('title')).toBe('Delete model modelName');
    });

    it('displays modal body', () => {
      expect(findModalText().exists()).toBe(true);
    });

    it('displays modal note', () => {
      expect(findNote().text()).toContain('Note:');
      expect(findNote().text()).toContain(
        'Deleting this model also deletes all its versions, including any imported or uploaded artifacts, and their associated settings.',
      );
    });

    it('submits the form when primary action is clicked', () => {
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('confirm-deletion').length).toEqual(1);
    });
  });
});
