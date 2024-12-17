import { GlButton, GlModal, GlFormInput, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteTagModal from '~/tags/components/delete_tag_modal.vue';
import eventHub from '~/tags/event_hub';
import { I18N_DELETE_TAG_MODAL } from '~/tags/constants';

let wrapper;

const tagName = 'test-tag';
const path = '/path/to/tag';
const isProtected = false;
const modalHideSpy = jest.fn();
const modalShowSpy = jest.fn();
const formSubmitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation();

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
          methods: {
            hide: modalHideSpy,
            show: modalShowSpy,
          },
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
    const expectedMessage = 'Deleting the test-tag tag cannot be undone.';

    beforeEach(() => {
      createComponent();
    });

    it('renders the modal correctly', () => {
      expect(findModal().props('title')).toBe(I18N_DELETE_TAG_MODAL.modalTitle);
      expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessage);
      expect(findCancelButton().text()).toBe(I18N_DELETE_TAG_MODAL.cancelButtonText);
      expect(findDeleteButton().text()).toBe(I18N_DELETE_TAG_MODAL.deleteButtonText);
      expect(findForm().attributes('action')).toBe(path);
    });

    it('submits the form when the delete button is clicked', () => {
      findDeleteButton().vm.$emit('click');

      expect(findForm().attributes('action')).toBe(path);
      expect(formSubmitSpy).toHaveBeenCalledTimes(1);
    });

    it('calls show on the modal when a `openModal` event is received through the event hub', () => {
      eventHub.$emit('openModal', {
        isProtected,
        tagName,
        path,
      });

      expect(modalShowSpy).toHaveBeenCalled();
    });

    it('calls hide on the modal when cancel button is clicked', () => {
      findCancelButton().vm.$emit('click');

      expect(modalHideSpy).toHaveBeenCalled();
    });
  });

  describe('Deleting a protected tag (for owner or maintainer)', () => {
    const expectedMessage = 'Deleting the test-tag protected tag cannot be undone.';
    const expectedConfirmationText = 'Please type the following to confirm: test-tag';

    beforeEach(() => {
      createComponent({ isProtected: true });
    });

    describe('rendering the modal correctly for a protected tag', () => {
      it('sets the modal title for a protected tag', () => {
        expect(findModal().props('title')).toBe(I18N_DELETE_TAG_MODAL.modalTitleProtectedTag);
      });

      it('renders the correct text in the modal message', () => {
        expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessage);
      });

      it('renders the protected tag name confirmation form with expected text and action', () => {
        expect(findForm().text()).toMatchInterpolatedText(expectedConfirmationText);
        expect(findForm().attributes('action')).toBe(path);
      });

      it('renders the buttons with the correct button text', () => {
        expect(findCancelButton().text()).toBe(I18N_DELETE_TAG_MODAL.cancelButtonText);
        expect(findDeleteButton().text()).toBe(I18N_DELETE_TAG_MODAL.deleteButtonTextProtectedTag);
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
