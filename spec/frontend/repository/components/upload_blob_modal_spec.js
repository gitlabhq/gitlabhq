import { GlModal, GlFormInput, GlFormTextarea, GlToggle, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

jest.mock('~/alert');
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

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCommitMessage = () => wrapper.findComponent(GlFormTextarea);
  const findBranchName = () => wrapper.findComponent(GlFormInput);
  const findMrToggle = () => wrapper.findComponent(GlToggle);
  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const actionButtonDisabledState = () => findModal().props('actionPrimary').attributes.disabled;
  const cancelButtonDisabledState = () => findModal().props('actionCancel').attributes.disabled;
  const actionButtonLoadingState = () => findModal().props('actionPrimary').attributes.loading;

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
            createComponent({ targetBranch: 'Not main' });

            await nextTick();

            expect(findMrToggle().exists()).toBe(true);
          });
        });
      }

      describe('completed form', () => {
        beforeEach(() => {
          findUploadDropzone().vm.$emit(
            'change',
            new File(['http://file.com?format=jpg'], 'file.jpg'),
          );
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
            mock.onPost(initialProps.path).reply(HTTP_STATUS_OK, { filePath: 'blah' });

            findModal().vm.$emit('primary', mockEvent);

            await waitForPromises();
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

          it('creates an alert error', () => {
            expect(createAlert).toHaveBeenCalledWith({
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
    const submitRequest = async () => {
      mock = new MockAdapter(axios);
      findModal().vm.$emit('primary', mockEvent);
      await waitForPromises();
    };

    describe('upload blob file', () => {
      beforeEach(() => {
        createComponent();
      });

      it('displays the default "Upload new file" modal title', () => {
        expect(findModal().props('title')).toBe('Upload new file');
      });

      it('display the defaul primary button text', () => {
        expect(findModal().props('actionPrimary').text).toBe('Upload file');
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

      it('makes a PUT request', async () => {
        await submitRequest();

        expect(mock.history.put).toHaveLength(1);
        expect(mock.history.post).toHaveLength(0);
        expect(mock.history.put[0].url).toBe(replacePath);
      });
    });
  });
});
