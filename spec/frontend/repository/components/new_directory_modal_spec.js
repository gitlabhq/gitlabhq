import { GlModal, GlFormTextarea, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import NewDirectoryModal from '~/repository/components/new_directory_modal.vue';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

const initialProps = {
  modalTitle: 'Create New Directory',
  modalId: 'modal-new-directory',
  commitMessage: 'Add new directory',
  targetBranch: 'some-target-branch',
  originalBranch: 'master',
  canPushCode: true,
  path: 'create_dir',
};

const defaultFormValue = {
  dirName: 'foo',
  originalBranch: initialProps.originalBranch,
  branchName: initialProps.targetBranch,
  commitMessage: initialProps.commitMessage,
  createNewMr: true,
};

describe('NewDirectoryModal', () => {
  let wrapper;
  let mock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NewDirectoryModal, {
      propsData: {
        ...initialProps,
        ...props,
      },
      attrs: {
        static: true,
        visible: true,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findDirName = () => wrapper.find('[name="dir_name"]');
  const findBranchName = () => wrapper.find('[name="branch_name"]');
  const findCommitMessage = () => wrapper.findComponent(GlFormTextarea);
  const findMrToggle = () => wrapper.findComponent(GlToggle);

  const fillForm = async (inputValue = {}) => {
    const {
      dirName = defaultFormValue.dirName,
      branchName = defaultFormValue.branchName,
      commitMessage = defaultFormValue.commitMessage,
      createNewMr = true,
    } = inputValue;

    await findDirName().vm.$emit('input', dirName);
    await findBranchName().vm.$emit('input', branchName);
    await findCommitMessage().vm.$emit('input', commitMessage);
    await findMrToggle().vm.$emit('change', createNewMr);
    await nextTick();
  };

  const submitForm = async () => {
    const mockEvent = { preventDefault: jest.fn() };
    findModal().vm.$emit('primary', mockEvent);
    await waitForPromises();
  };

  it('renders modal component', () => {
    createComponent();

    const { modalTitle: title } = initialProps;

    expect(findModal().props()).toMatchObject({
      title,
      size: 'md',
      actionPrimary: {
        text: NewDirectoryModal.i18n.PRIMARY_OPTIONS_TEXT,
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
  });

  describe('form', () => {
    it.each`
      component            | defaultValue                  | canPushCode | targetBranch                 | originalBranch                 | exist
      ${findDirName}       | ${undefined}                  | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${findBranchName}    | ${initialProps.targetBranch}  | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${findBranchName}    | ${undefined}                  | ${false}    | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${false}
      ${findCommitMessage} | ${initialProps.commitMessage} | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${findMrToggle}      | ${'true'}                     | ${true}     | ${'new-target-branch'}       | ${'master'}                    | ${true}
      ${findMrToggle}      | ${'true'}                     | ${true}     | ${'master'}                  | ${'master'}                    | ${true}
    `(
      'has the correct form fields',
      ({ component, defaultValue, canPushCode, targetBranch, originalBranch, exist }) => {
        createComponent({
          canPushCode,
          targetBranch,
          originalBranch,
        });
        const formField = component();

        if (!exist) {
          expect(formField.exists()).toBe(false);
          return;
        }

        expect(formField.exists()).toBe(true);
        expect(formField.attributes('value')).toBe(defaultValue);
      },
    );
  });

  describe('form submission', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('valid form', () => {
      beforeEach(() => {
        createComponent();
      });

      it('passes the formData', async () => {
        const {
          dirName,
          branchName,
          commitMessage,
          originalBranch,
          createNewMr,
        } = defaultFormValue;
        mock.onPost(initialProps.path).reply(HTTP_STATUS_OK, {});
        await fillForm();
        await submitForm();

        expect(mock.history.post[0].data.get('dir_name')).toEqual(dirName);
        expect(mock.history.post[0].data.get('branch_name')).toEqual(branchName);
        expect(mock.history.post[0].data.get('commit_message')).toEqual(commitMessage);
        expect(mock.history.post[0].data.get('original_branch')).toEqual(originalBranch);
        expect(mock.history.post[0].data.get('create_merge_request')).toEqual(String(createNewMr));
      });

      it('does not submit "create_merge_request" formData if createNewMr is not checked', async () => {
        mock.onPost(initialProps.path).reply(HTTP_STATUS_OK, {});
        await fillForm({ createNewMr: false });
        await submitForm();
        expect(mock.history.post[0].data.get('create_merge_request')).toBeNull();
      });

      it('redirects to the new directory', async () => {
        const response = { filePath: 'new-dir-path' };
        mock.onPost(initialProps.path).reply(HTTP_STATUS_OK, response);

        await fillForm({ dirName: 'foo', branchName: 'master', commitMessage: 'foo' });
        await submitForm();

        expect(visitUrl).toHaveBeenCalledWith(response.filePath);
      });
    });

    describe('invalid form', () => {
      beforeEach(() => {
        createComponent();
      });

      it('disables submit button', async () => {
        await fillForm({ dirName: '', branchName: '', commitMessage: '' });
        expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
      });

      it('creates an alert error', async () => {
        mock.onPost(initialProps.path).timeout();

        await fillForm({ dirName: 'foo', branchName: 'master', commitMessage: 'foo' });
        await submitForm();

        expect(createAlert).toHaveBeenCalledWith({
          message: NewDirectoryModal.i18n.ERROR_MESSAGE,
        });
      });
    });
  });
});
