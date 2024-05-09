import { GlButton, GlModal, GlFormInput, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteBranchModal from '~/branches/components/delete_branch_modal.vue';
import eventHub from '~/branches/event_hub';

let wrapper;
let showMock;
let hideMock;

const branchName = 'test_modal';
const defaultBranchName = 'default';
const deletePath = '/path/to/branch';
const merged = false;
const isProtectedBranch = false;

const createComponent = () => {
  showMock = jest.fn();
  hideMock = jest.fn();

  wrapper = extendedWrapper(
    shallowMount(DeleteBranchModal, {
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
          methods: {
            show: showMock,
            hide: hideMock,
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
const findDeleteButton = () => wrapper.findByTestId('delete-branch-confirmation-button');
const findCancelButton = () => wrapper.findByTestId('delete-branch-cancel-button');
const findFormInput = () => wrapper.findComponent(GlFormInput);
const findForm = () => wrapper.find('form');
const createSubmitFormSpy = () => jest.spyOn(findForm().element, 'submit');
const triggerFormInput = (branch) => {
  findFormInput().vm.$emit('input', branch || 'hello');
};

const emitOpenModal = (data = {}) =>
  eventHub.$emit('openModal', {
    isProtectedBranch,
    branchName,
    defaultBranchName,
    deletePath,
    merged,
    ...data,
  });

describe('Delete branch modal', () => {
  const expectedUnmergedWarning =
    "This branch hasn't been merged into default. To avoid data loss, consider merging this branch before deleting it.";

  beforeEach(() => {
    createComponent();

    emitOpenModal();

    showMock.mockClear();
    hideMock.mockClear();
  });

  describe('Deleting a regular branch', () => {
    const expectedTitle = 'Delete branch. Are you ABSOLUTELY SURE?';
    const expectedWarning = "You're about to permanently delete the branch test_modal.";
    const expectedMessage = `${expectedWarning} ${expectedUnmergedWarning}`;

    it('renders the modal correctly', () => {
      expect(findModal().props('title')).toBe(expectedTitle);
      expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessage);
      expect(findCancelButton().text()).toBe('Cancel, keep branch');
      expect(findDeleteButton().text()).toBe('Yes, delete branch');
      expect(findForm().attributes('action')).toBe(deletePath);
    });

    it('submits the form when the delete button is clicked', () => {
      const submitSpy = createSubmitFormSpy();

      expect(submitSpy).not.toHaveBeenCalled();

      findDeleteButton().trigger('click');

      expect(findForm().attributes('action')).toBe(deletePath);
      expect(submitSpy).toHaveBeenCalled();
    });

    it('calls show on the modal when a `openModal` event is received through the event hub', () => {
      expect(showMock).not.toHaveBeenCalled();

      emitOpenModal();

      expect(showMock).toHaveBeenCalled();
    });

    it('calls hide on the modal when cancel button is clicked', () => {
      expect(hideMock).not.toHaveBeenCalled();

      findCancelButton().trigger('click');

      expect(hideMock).toHaveBeenCalled();
    });
  });

  describe('Deleting a protected branch (for owner or maintainer)', () => {
    const expectedTitleProtected = 'Delete protected branch. Are you ABSOLUTELY SURE?';
    const expectedWarningProtected =
      "You're about to permanently delete the protected branch test_modal.";
    const expectedMessageProtected = `${expectedWarningProtected} ${expectedUnmergedWarning}`;
    const expectedConfirmationText =
      'After you confirm and select Yes, delete protected branch, you cannot recover this branch. Please type the following to confirm: test_modal';

    beforeEach(() => {
      emitOpenModal({
        isProtectedBranch: true,
      });
    });

    describe('rendering the modal correctly for a protected branch', () => {
      it('sets the modal title for a protected branch', () => {
        expect(findModal().props('title')).toBe(expectedTitleProtected);
      });

      it('renders the correct text in the modal message', () => {
        expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessageProtected);
      });

      it('renders the protected branch name confirmation form with expected text and action', () => {
        expect(findForm().text()).toMatchInterpolatedText(expectedConfirmationText);
        expect(findForm().attributes('action')).toBe(deletePath);
      });

      it('renders the buttons with the correct button text', () => {
        expect(findCancelButton().text()).toBe('Cancel, keep branch');
        expect(findDeleteButton().text()).toBe('Yes, delete protected branch');
      });
    });

    it('renders the modal with delete button disabled', () => {
      expect(findDeleteButton().props('disabled')).toBe(true);
    });

    it('enables the delete button when branch name is confirmed and fires submit', async () => {
      triggerFormInput(branchName);

      await waitForPromises();

      expect(findDeleteButton().props('disabled')).not.toBe(true);

      const submitSpy = createSubmitFormSpy();

      expect(submitSpy).not.toHaveBeenCalled();

      findDeleteButton().trigger('click');

      expect(submitSpy).toHaveBeenCalled();
    });

    it('enables the delete button when branch name is confirmed and form submits', async () => {
      triggerFormInput(branchName);

      await waitForPromises();

      expect(findDeleteButton().props('disabled')).not.toBe(true);

      const submitSpy = createSubmitFormSpy();

      expect(submitSpy).not.toHaveBeenCalled();

      findForm().trigger('submit');

      expect(submitSpy).toHaveBeenCalled();
    });

    it('doesn`t fire when form submits', async () => {
      triggerFormInput();

      await waitForPromises();

      const submitSpy = createSubmitFormSpy();

      findForm().trigger('submit');

      expect(submitSpy).not.toHaveBeenCalled();
    });
  });

  describe('Deleting a merged branch', () => {
    beforeEach(() => {
      emitOpenModal({ merged: true });
    });

    it('does not include the unmerged branch warning when merged is true', () => {
      expect(findModalMessage().text()).not.toContain(expectedUnmergedWarning);
    });
  });
});
