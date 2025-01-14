import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import CreateWorkItemCancelConfirmationModal from '~/work_items/components/create_work_item_cancel_confirmation_modal.vue';

describe('CreateWorkItemCancelConfirmationModal', () => {
  let wrapper;

  const findComponent = () => wrapper.findComponent(CreateWorkItemCancelConfirmationModal);
  const findModal = () => wrapper.findComponent(GlModal);
  const findContinueEditingButton = () =>
    wrapper.find('[data-testid="create-work-item-continue-editing"]');
  const findDiscardButton = () => wrapper.find('[data-testid="create-work-item-discard"]');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CreateWorkItemCancelConfirmationModal, {
      propsData: {
        isVisible: true,
        ...props,
      },
      stubs: {
        GlModal,
      },
    });
  };

  describe('default', () => {
    it('component is rendered', () => {
      createComponent();

      expect(findComponent().exists()).toBe(true);
    });

    it('shows the modal when visible prop is true', () => {
      createComponent();

      expect(findModal().props('visible')).toBe(true);
    });

    it('hides the modal when visible prop is false', () => {
      createComponent({ isVisible: false });

      expect(findModal().props('visible')).toBe(false);
    });
  });

  describe('modal content', () => {
    it('displays the correct content in the modal body', () => {
      createComponent({ workItemTypeName: 'Epic' });

      expect(wrapper.text()).toContain('Are you sure you want to cancel creating this epic?');
    });

    it('displays the action buttons', () => {
      createComponent();

      expect(findContinueEditingButton().text()).toBe('Continue editing');
      expect(findDiscardButton().text()).toBe('Discard changes');
    });
  });

  describe('modal events', () => {
    it('emits proper event when "Continue editing" button is clicked', () => {
      createComponent();

      findContinueEditingButton().vm.$emit('click');

      expect(wrapper.emitted('continueEditing').length).toBe(1);
    });

    it('emits proper event when "Discard changes" button is clicked', async () => {
      createComponent();

      await findDiscardButton().vm.$emit('click');

      expect(wrapper.emitted('discardDraft').length).toBe(1);
    });
  });
});
