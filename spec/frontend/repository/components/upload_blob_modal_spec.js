import { GlModal, GlFormInput, GlFormTextarea, GlToggle, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { trackFileUploadEvent } from '~/projects/upload_file_experiment_tracking';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

jest.mock('~/projects/upload_file_experiment_tracking');
jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: () => '/new_upload',
}));

const initialProps = {
  modalId: 'upload-blob',
  commitMessage: 'Upload New File',
  targetBranch: 'main',
  originalBranch: 'main',
  canPushCode: true,
  path: 'new_upload',
};

describe('UploadBlobModal', () => {
  let wrapper;
  let mock;

  const mockEvent = { preventDefault: jest.fn() };

  const createComponent = (props) => {
    wrapper = shallowMount(UploadBlobModal, {
      propsData: {
        ...initialProps,
        ...props,
      },
      mocks: {
        $route: {
          params: {
            path: '',
          },
        },
      },
    });
  };

  const findModal = () => wrapper.find(GlModal);
  const findAlert = () => wrapper.find(GlAlert);
  const findCommitMessage = () => wrapper.find(GlFormTextarea);
  const findBranchName = () => wrapper.find(GlFormInput);
  const findMrToggle = () => wrapper.find(GlToggle);
  const findUploadDropzone = () => wrapper.find(UploadDropzone);
  const actionButtonDisabledState = () => findModal().props('actionPrimary').attributes[0].disabled;
  const cancelButtonDisabledState = () => findModal().props('actionCancel').attributes[0].disabled;
  const actionButtonLoadingState = () => findModal().props('actionPrimary').attributes[0].loading;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    canPushCode | displayBranchName | displayForkedBranchMessage
    ${true}     | ${true}           | ${false}
    ${false}    | ${false}          | ${true}
  `(
    'canPushCode = $canPushCode',
    ({ canPushCode, displayBranchName, displayForkedBranchMessage }) => {
      beforeEach(() => {
        createComponent({ canPushCode });
      });

      it('displays the modal', () => {
        expect(findModal().exists()).toBe(true);
      });

      it('includes the upload dropzone', () => {
        expect(findUploadDropzone().exists()).toBe(true);
      });

      it('includes the commit message', () => {
        expect(findCommitMessage().exists()).toBe(true);
      });

      it('displays the disabled upload button', () => {
        expect(actionButtonDisabledState()).toBe(true);
      });

      it('displays the enabled cancel button', () => {
        expect(cancelButtonDisabledState()).toBe(false);
      });

      it('does not display the MR toggle', () => {
        expect(findMrToggle().exists()).toBe(false);
      });

      it(`${
        displayForkedBranchMessage ? 'displays' : 'does not display'
      } the forked branch message`, () => {
        expect(findAlert().exists()).toBe(displayForkedBranchMessage);
      });

      it(`${displayBranchName ? 'displays' : 'does not display'} the branch name`, () => {
        expect(findBranchName().exists()).toBe(displayBranchName);
      });

      if (canPushCode) {
        describe('when changing the branch name', () => {
          it('displays the MR toggle', async () => {
            wrapper.setData({ target: 'Not main' });

            await wrapper.vm.$nextTick();

            expect(findMrToggle().exists()).toBe(true);
          });
        });
      }

      describe('completed form', () => {
        beforeEach(() => {
          wrapper.setData({
            file: { type: 'jpg' },
            filePreviewURL: 'http://file.com?format=jpg',
          });
        });

        it('enables the upload button when the form is completed', () => {
          expect(actionButtonDisabledState()).toBe(false);
        });

        describe('form submission', () => {
          beforeEach(() => {
            mock = new MockAdapter(axios);

            findModal().vm.$emit('primary', mockEvent);
          });

          afterEach(() => {
            mock.restore();
          });

          it('disables the upload button', () => {
            expect(actionButtonDisabledState()).toBe(true);
          });

          it('sets the upload button to loading', () => {
            expect(actionButtonLoadingState()).toBe(true);
          });
        });

        describe('successful response', () => {
          beforeEach(async () => {
            mock = new MockAdapter(axios);
            mock.onPost(initialProps.path).reply(httpStatusCodes.OK, { filePath: 'blah' });

            findModal().vm.$emit('primary', mockEvent);

            await waitForPromises();
          });

          it('tracks the click_upload_modal_trigger event when opening the modal', () => {
            expect(trackFileUploadEvent).toHaveBeenCalledWith('click_upload_modal_form_submit');
          });

          it('redirects to the uploaded file', () => {
            expect(visitUrl).toHaveBeenCalled();
          });

          afterEach(() => {
            mock.restore();
          });
        });

        describe('error response', () => {
          beforeEach(async () => {
            mock = new MockAdapter(axios);
            mock.onPost(initialProps.path).timeout();

            findModal().vm.$emit('primary', mockEvent);

            await waitForPromises();
          });

          it('does not track an event', () => {
            expect(trackFileUploadEvent).not.toHaveBeenCalled();
          });

          it('creates a flash error', () => {
            expect(createFlash).toHaveBeenCalledWith({
              message: 'Error uploading file. Please try again.',
            });
          });

          afterEach(() => {
            mock.restore();
          });
        });
      });
    },
  );

  describe('blob file submission type', () => {
    const submitForm = async () => {
      wrapper.vm.uploadFile = jest.fn();
      wrapper.vm.replaceFile = jest.fn();
      wrapper.vm.submitForm();
      await wrapper.vm.$nextTick();
    };

    const submitRequest = async () => {
      mock = new MockAdapter(axios);
      findModal().vm.$emit('primary', mockEvent);
      await waitForPromises();
    };

    describe('upload blob file', () => {
      beforeEach(() => {
        createComponent();
      });

      it('displays the default "Upload New File" modal title  ', () => {
        expect(findModal().props('title')).toBe('Upload New File');
      });

      it('display the defaul primary button text', () => {
        expect(findModal().props('actionPrimary').text).toBe('Upload file');
      });

      it('calls the default uploadFile when the form submit', async () => {
        await submitForm();

        expect(wrapper.vm.uploadFile).toHaveBeenCalled();
        expect(wrapper.vm.replaceFile).not.toHaveBeenCalled();
      });

      it('makes a POST request', async () => {
        await submitRequest();

        expect(mock.history.put).toHaveLength(0);
        expect(mock.history.post).toHaveLength(1);
      });
    });

    describe('replace blob file', () => {
      const modalTitle = 'Replace foo.js';
      const replacePath = 'replace-path';
      const primaryBtnText = 'Replace file';

      beforeEach(() => {
        createComponent({
          modalTitle,
          replacePath,
          primaryBtnText,
        });
      });

      it('displays the passed modal title', () => {
        expect(findModal().props('title')).toBe(modalTitle);
      });

      it('display the passed primary button text', () => {
        expect(findModal().props('actionPrimary').text).toBe(primaryBtnText);
      });

      it('calls the replaceFile when the form submit', async () => {
        await submitForm();

        expect(wrapper.vm.replaceFile).toHaveBeenCalled();
        expect(wrapper.vm.uploadFile).not.toHaveBeenCalled();
      });

      it('makes a PUT request', async () => {
        await submitRequest();

        expect(mock.history.put).toHaveLength(1);
        expect(mock.history.post).toHaveLength(0);
        expect(mock.history.put[0].url).toBe(replacePath);
      });
    });
  });
});
