import { GlButton, GlModal, GlFormInput, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteTagModal from '~/tags/components/delete_tag_modal.vue';
import eventHub from '~/tags/event_hub';

let wrapper;

const tagName = 'test-tag';
const path = '/path/to/tag';
const isProtected = false;

const createComponent = (data = {}) => {
  wrapper = extendedWrapper(
    shallowMount(DeleteTagModal, {
      data() {
        return {
          tagName,
          path,
          isProtected,
          ...data,
        };
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        GlButton,
        GlFormInput,
        GlSprintf,
      },
    }),
  );
};

const findModal = () => wrapper.findComponent(GlModal);
const findModalMessage = () => wrapper.findByTestId('modal-message');
const findDeleteButton = () => wrapper.findByTestId('delete-tag-confirmation-button');
const findCancelButton = () => wrapper.findByTestId('delete-tag-cancel-button');
const findFormInput = () => wrapper.findComponent(GlFormInput);
const findForm = () => wrapper.find('form');

describe('Delete tag modal', () => {
  describe('Deleting a regular tag', () => {
    const expectedTitle = 'Delete tag. Are you ABSOLUTELY SURE?';
    const expectedMessage = "You're about to permanently delete the tag test-tag.";

    beforeEach(() => {
      createComponent();
    });

    it('renders the modal correctly', () => {
      expect(findModal().props('title')).toBe(expectedTitle);
      expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessage);
      expect(findCancelButton().text()).toBe('Cancel, keep tag');
      expect(findDeleteButton().text()).toBe('Yes, delete tag');
      expect(findForm().attributes('action')).toBe(path);
    });

    it('submits the form when the delete button is clicked', () => {
      const submitFormSpy = jest.spyOn(wrapper.vm.$refs.form, 'submit');

      findDeleteButton().trigger('click');

      expect(findForm().attributes('action')).toBe(path);
      expect(submitFormSpy).toHaveBeenCalled();
    });

    it('calls show on the modal when a `openModal` event is received through the event hub', () => {
      const showSpy = jest.spyOn(wrapper.vm.$refs.modal, 'show');

      eventHub.$emit('openModal', {
        isProtected,
        tagName,
        path,
      });

      expect(showSpy).toHaveBeenCalled();
    });

    it('calls hide on the modal when cancel button is clicked', () => {
      const closeModalSpy = jest.spyOn(wrapper.vm.$refs.modal, 'hide');

      findCancelButton().trigger('click');

      expect(closeModalSpy).toHaveBeenCalled();
    });
  });

  describe('Deleting a protected tag (for owner or maintainer)', () => {
    const expectedTitleProtected = 'Delete protected tag. Are you ABSOLUTELY SURE?';
    const expectedMessageProtected =
      "You're about to permanently delete the protected tag test-tag.";
    const expectedConfirmationText =
      'After you confirm and select Yes, delete protected tag, you cannot recover this tag. Please type the following to confirm: test-tag';

    beforeEach(() => {
      createComponent({ isProtected: true });
    });

    describe('rendering the modal correctly for a protected tag', () => {
      it('sets the modal title for a protected tag', () => {
        expect(findModal().props('title')).toBe(expectedTitleProtected);
      });

      it('renders the correct text in the modal message', () => {
        expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessageProtected);
      });

      it('renders the protected tag name confirmation form with expected text and action', () => {
        expect(findForm().text()).toMatchInterpolatedText(expectedConfirmationText);
        expect(findForm().attributes('action')).toBe(path);
      });

      it('renders the buttons with the correct button text', () => {
        expect(findCancelButton().text()).toBe('Cancel, keep tag');
        expect(findDeleteButton().text()).toBe('Yes, delete protected tag');
      });
    });

    it('opens with the delete button disabled and enables it when tag name is confirmed', async () => {
      expect(findDeleteButton().props('disabled')).toBe(true);

      findFormInput().vm.$emit('input', tagName);

      await waitForPromises();

      expect(findDeleteButton().props('disabled')).not.toBe(true);
    });
  });
});
