import { GlButton, GlModal, GlFormInput, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteBranchModal from '~/branches/components/delete_branch_modal.vue';
import eventHub from '~/branches/event_hub';

let wrapper;

const branchName = 'test_modal';
const defaultBranchName = 'default';
const deletePath = '/path/to/branch';
const merged = false;
const isProtectedBranch = false;

const createComponent = (data = {}) => {
  wrapper = extendedWrapper(
    shallowMount(DeleteBranchModal, {
      data() {
        return {
          branchName,
          deletePath,
          defaultBranchName,
          merged,
          isProtectedBranch,
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
const findDeleteButton = () => wrapper.findByTestId('delete-branch-confirmation-button');
const findCancelButton = () => wrapper.findByTestId('delete-branch-cancel-button');
const findFormInput = () => wrapper.findComponent(GlFormInput);
const findForm = () => wrapper.find('form');

describe('Delete branch modal', () => {
  const expectedUnmergedWarning =
    'This branch hasn’t been merged into default. To avoid data loss, consider merging this branch before deleting it.';

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Deleting a regular branch', () => {
    const expectedTitle = 'Delete branch. Are you ABSOLUTELY SURE?';
    const expectedWarning = "You're about to permanently delete the branch test_modal.";
    const expectedMessage = `${expectedWarning} ${expectedUnmergedWarning}`;

    beforeEach(() => {
      createComponent();
    });

    it('renders the modal correctly', () => {
      expect(findModal().props('title')).toBe(expectedTitle);
      expect(findModalMessage().text()).toMatchInterpolatedText(expectedMessage);
      expect(findCancelButton().text()).toBe('Cancel, keep branch');
      expect(findDeleteButton().text()).toBe('Yes, delete branch');
      expect(findForm().attributes('action')).toBe(deletePath);
    });

    it('submits the form when the delete button is clicked', () => {
      const submitFormSpy = jest.spyOn(wrapper.vm.$refs.form, 'submit');

      findDeleteButton().trigger('click');

      expect(findForm().attributes('action')).toBe(deletePath);
      expect(submitFormSpy).toHaveBeenCalled();
    });

    it('calls show on the modal when a `openModal` event is received through the event hub', async () => {
      const showSpy = jest.spyOn(wrapper.vm.$refs.modal, 'show');

      eventHub.$emit('openModal', {
        isProtectedBranch,
        branchName,
        defaultBranchName,
        deletePath,
        merged,
      });

      expect(showSpy).toHaveBeenCalled();
    });

    it('calls hide on the modal when cancel button is clicked', () => {
      const closeModalSpy = jest.spyOn(wrapper.vm.$refs.modal, 'hide');

      findCancelButton().trigger('click');

      expect(closeModalSpy).toHaveBeenCalled();
    });
  });

  describe('Deleting a protected branch (for owner or maintainer)', () => {
    const expectedTitleProtected = 'Delete protected branch. Are you ABSOLUTELY SURE?';
    const expectedWarningProtected =
      "You're about to permanently delete the protected branch test_modal.";
    const expectedMessageProtected = `${expectedWarningProtected} ${expectedUnmergedWarning}`;
    const expectedConfirmationText =
      'Once you confirm and press Yes, delete protected branch, it cannot be undone or recovered. Please type the following to confirm: test_modal';

    beforeEach(() => {
      createComponent({ isProtectedBranch: true });
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

    it('opens with the delete button disabled and enables it when branch name is confirmed', async () => {
      expect(findDeleteButton().props('disabled')).toBe(true);

      findFormInput().vm.$emit('input', branchName);

      await waitForPromises();

      expect(findDeleteButton().props('disabled')).not.toBe(true);
    });
  });

  describe('Deleting a merged branch', () => {
    it('does not include the unmerged branch warning when merged is true', () => {
      createComponent({ merged: true });

      expect(findModalMessage().html()).not.toContain(expectedUnmergedWarning);
    });
  });
});
