import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { logError } from '~/lib/logger';

jest.mock('~/alert');
jest.mock('~/lib/logger');

const NEW_PATH = '/new-upload';
const REPLACE_PATH = '/replace-path';
const ERROR_UPLOAD = 'Failed to upload file. See exception details for more information.';
const ERROR_REPLACE = 'Failed to replace file. See exception details for more information.';

const initialProps = {
  modalId: 'upload-blob',
  commitMessage: 'Upload New File',
  targetBranch: 'main',
  originalBranch: 'main',
  canPushCode: true,
  canPushToBranch: true,
  path: NEW_PATH,
};

describe('UploadBlobModal', () => {
  let wrapper;
  let mock;
  let visitUrlSpy;

  const createComponent = (props) => {
    wrapper = shallowMount(UploadBlobModal, {
      propsData: {
        ...initialProps,
        ...props,
      },
      stubs: {
        CommitChangesModal,
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

  beforeEach(() => {
    visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl');
    mock = new MockAdapter(axios);

    mock.onPut(REPLACE_PATH).replyOnce(HTTP_STATUS_OK, { filePath: '/replace_file' });
  });

  afterEach(() => {
    mock.restore();
  });

  const setupUploadMock = () => {
    mock.onPost(NEW_PATH).replyOnce(HTTP_STATUS_OK, { filePath: '/new_file' });
  };
  const setupUploadMockAsError = () => {
    mock.onPost(NEW_PATH).timeout();
  };
  const setupReplaceMock = () => {
    mock.onPut(REPLACE_PATH).replyOnce(HTTP_STATUS_OK, { filePath: '/replace_file' });
  };
  const setupReplaceMockAsError = () => {
    mock.onPut(REPLACE_PATH).timeout();
  };

  const findCommitChangesModal = () => wrapper.findComponent(CommitChangesModal);
  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findFileIcon = () => wrapper.findComponent(FileIcon);
  const submitForm = async () => {
    findCommitChangesModal().vm.$emit('submit-form', new FormData());

    await axios.waitForAll();
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders commit changes modal', () => {
      expect(findCommitChangesModal().props()).toMatchObject({
        modalId: 'upload-blob',
        commitMessage: 'Upload New File',
        targetBranch: 'main',
        originalBranch: 'main',
        canPushCode: true,
        canPushToBranch: true,
        valid: false,
        loading: false,
        emptyRepo: false,
      });
    });

    it('includes the upload dropzone', () => {
      expect(findUploadDropzone().exists()).toBe(true);
    });
  });

  describe.each`
    props                            | setupMock           | setupMockAsError           | expectedVisitUrl   | expectedError
    ${{}}                            | ${setupUploadMock}  | ${setupUploadMockAsError}  | ${'/new_file'}     | ${ERROR_UPLOAD}
    ${{ replacePath: REPLACE_PATH }} | ${setupReplaceMock} | ${setupReplaceMockAsError} | ${'/replace_file'} | ${ERROR_REPLACE}
  `(
    'with props=$props',
    ({ props, setupMock, setupMockAsError, expectedVisitUrl, expectedError }) => {
      beforeEach(async () => {
        setupMock();
        createComponent(props);
        await nextTick();
      });

      describe('completed form', () => {
        beforeEach(() => {
          findUploadDropzone().vm.$emit(
            'change',
            new File(['http://gitlab.com/-/uploads/file.jpg'], 'file.jpg'),
          );
        });

        it('enables the upload button when the form is completed', () => {
          expect(findCommitChangesModal().props('valid')).toBe(true);
        });

        it('displays the correct file type icon', () => {
          expect(findFileIcon().props('fileName')).toBe('file.jpg');
        });

        it('on submit, redirects to the uploaded file', async () => {
          await submitForm();

          expect(visitUrlSpy).toHaveBeenCalledWith(expectedVisitUrl);
        });

        it('on error, creates an alert error', async () => {
          setupMockAsError();
          await submitForm();

          const mockError = new Error('timeout of 0ms exceeded');

          expect(createAlert).toHaveBeenCalledWith({
            message: 'Error uploading file. Please try again.',
          });
          expect(logError).toHaveBeenCalledWith(expectedError, mockError);
        });
      });
    },
  );
});
