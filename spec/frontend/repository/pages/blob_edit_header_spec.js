import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlButton } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
  HTTP_STATUS_FORBIDDEN,
} from '~/lib/utils/http_status';
import { saveAlertToLocalStorage } from '~/lib/utils/local_storage_alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import BlobEditHeader from '~/repository/pages/blob_edit_header.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { stubComponent } from 'helpers/stub_component';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

jest.mock('~/alert');
jest.mock('~/lib/utils/local_storage_alert');
jest.mock('lodash/uniqueId', () => {
  return jest.fn((input) => `${input}1`);
});

describe('BlobEditHeader', () => {
  let wrapper;
  let mock;
  let visitUrlSpy;

  const content = 'some \r\n content \n';

  const mockEditor = {
    getFileContent: jest.fn().mockReturnValue(content),
    getOriginalFilePath: jest.fn().mockReturnValue('test.js'),
    filepathFormMediator: {
      $filenameInput: { val: jest.fn().mockReturnValue('test.js') },
      toggleValidationError: jest.fn(),
    },
  };

  const createWrapper = ({ action = 'update', glFeatures = {}, provided = {} } = {}) => {
    wrapper = shallowMountExtended(BlobEditHeader, {
      provide: {
        action,
        editor: mockEditor,
        updatePath: '/update',
        cancelPath: '/cancel',
        originalBranch: 'main',
        targetBranch: 'feature',
        blobName: 'test.js',
        canPushCode: true,
        canPushToBranch: true,
        emptyRepo: false,
        branchAllowsCollaboration: false,
        lastCommitSha: '782426692977b2cedb4452ee6501a404410f9b00',
        projectId: 123,
        projectPath: 'gitlab-org/gitlab',
        newMergeRequestPath: 'merge_request/new/123',
        ...provided,
        glFeatures: { blobEditRefactor: true, ...glFeatures },
      },
      mixins: [glFeatureFlagMixin()],
      stubs: {
        PageHeading,
        CommitChangesModal: stubComponent(CommitChangesModal, {
          methods: {
            show: jest.fn(),
          },
        }),
      },
    });
  };

  beforeEach(() => {
    window.gon = { api_version: 'v4' };

    visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl');
    mock = new MockAdapter(axios);
    createWrapper();
  });

  afterEach(() => {
    jest.clearAllMocks();
    mock.restore();
  });

  const findTitle = () => wrapper.find('h1');
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findCommitChangesModal = () => wrapper.findComponent(CommitChangesModal);
  const findCommitChangesButton = () => wrapper.findByTestId('blob-edit-header-commit-button');
  const findCancelButton = () => wrapper.findByTestId('blob-edit-header-cancel-button');

  const clickCommitChangesButton = async () => {
    findCommitChangesButton().vm.$emit('click');
    await nextTick();
  };

  const submitForm = async () => {
    const formData = new FormData();
    formData.append('commit_message', 'Test commit');
    formData.append('branch_name', 'feature');
    formData.append('original_branch', 'main');

    findCommitChangesModal().vm.$emit('submit-form', formData);

    await axios.waitForAll();
  };

  it('renders title with two buttons', () => {
    expect(findTitle().text()).toBe('Edit file');
    const buttons = findButtons();
    expect(buttons).toHaveLength(2);
    expect(buttons.at(0).text()).toBe('Cancel');
    expect(buttons.at(1).text()).toBe('Commit changes');
  });

  it('retrieves edit content, when opening the modal', () => {
    clickCommitChangesButton();
    expect(mockEditor.getFileContent).toHaveBeenCalled();
  });

  it('opens commit changes modal with correct props', () => {
    expect(findCommitChangesModal().props()).toEqual({
      modalId: 'update-modal1',
      canPushCode: true,
      canPushToBranch: true,
      commitMessage: 'Edit test.js',
      emptyRepo: false,
      isUsingLfs: false,
      originalBranch: 'main',
      targetBranch: 'feature',
      loading: false,
      branchAllowsCollaboration: false,
      valid: true,
      error: null,
    });
  });

  describe('for edit blob', () => {
    describe('when blobEditRefactor is enabled', () => {
      beforeEach(() => {
        clickCommitChangesButton();
      });

      it('shows confirmation message on cancel button', () => {
        expect(findCancelButton().attributes('data-confirm')).toBe(
          'Leave edit mode? All unsaved changes will be lost.',
        );
      });

      it('on submit, saves success message to localStorage and redirects to the updated file', async () => {
        // First click the commit button to open the modal and set up the file content
        mock.onPut().replyOnce(HTTP_STATUS_OK, {
          branch: 'feature',
          file_path: 'test.js',
        });
        await submitForm();

        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message:
            'Your %{changesLinkStart}changes%{changesLinkEnd} have been committed successfully. You can now submit a merge request to get this change into the original branch.',
          messageLinks: {
            changesLink: 'http://test.host/gitlab-org/gitlab/-/blob/feature/test.js',
          },
          variant: 'info',
        });

        expect(mock.history.put).toHaveLength(1);
        expect(mock.history.put[0].url).toBe('/api/v4/projects/123/repository/files/test.js');
        const putData = JSON.parse(mock.history.put[0].data);
        expect(putData.content).toBe(content);
        expect(visitUrlSpy).toHaveBeenCalledWith(
          'http://test.host/gitlab-org/gitlab/-/blob/feature/test.js',
        );
      });

      it('on submit to the same branch, saves shorter success message to localStorage', async () => {
        mock.onPut().replyOnce(HTTP_STATUS_OK, {
          branch: 'main', // Same as originalBranch
          file_path: 'test.js',
        });

        await submitForm();
        await axios.waitForAll();

        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message:
            'Your %{changesLinkStart}changes%{changesLinkEnd} have been committed successfully.',
          messageLinks: {
            changesLink: 'http://test.host/gitlab-org/gitlab/-/blob/main/test.js',
          },
          variant: 'info',
        });

        expect(visitUrlSpy).toHaveBeenCalledWith(
          'http://test.host/gitlab-org/gitlab/-/blob/main/test.js',
        );
      });

      it('on submit to the same branch from the existing MR, redirects back to the MR', async () => {
        // Mock URL with from_merge_request_iid parameter
        const originalLocation = window.location;
        delete window.location;
        window.location = new URL(
          'http://test.host/gitlab-org/gitlab/-/edit/main/test.js?from_merge_request_iid=19',
        );

        const removeParamsSpy = jest.spyOn(urlUtility, 'removeParams');
        removeParamsSpy.mockReturnValue('http://test.host/gitlab-org/gitlab/-/merge_requests/19');

        mock.onPut().replyOnce(HTTP_STATUS_OK, {
          branch: 'main', // Same as originalBranch
          file_path: 'test.js',
        });

        await submitForm();
        await axios.waitForAll();

        expect(removeParamsSpy).toHaveBeenCalledWith(
          ['from_merge_request_iid'],
          'http://test.host/gitlab-org/gitlab/-/merge_requests/19?from_merge_request_iid=19',
        );
        expect(visitUrlSpy).toHaveBeenCalledWith(
          'http://test.host/gitlab-org/gitlab/-/merge_requests/19',
        );
        expect(saveAlertToLocalStorage).not.toHaveBeenCalled();

        // Restore original location
        window.location = originalLocation;
        removeParamsSpy.mockRestore();
      });

      it('on submit to new branch to a fork repo, saves success message with "original project" text', async () => {
        // Create wrapper with canPushToBranch: false to simulate fork scenario
        createWrapper({
          glFeatures: { blobEditRefactor: true },
          provided: { canPushToBranch: false },
        });

        // Need to click the commit button first to open modal and set up file content
        clickCommitChangesButton();

        mock.onPut().replyOnce(HTTP_STATUS_OK, {
          branch: 'feature',
          file_path: 'test.js',
        });
        await submitForm();

        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message:
            'Your %{changesLinkStart}changes%{changesLinkEnd} have been committed successfully. You can now submit a merge request to get this change into the original project.',
          messageLinks: {
            changesLink: 'http://test.host/gitlab-org/gitlab/-/blob/feature/test.js',
          },
          variant: 'info',
        });

        expect(visitUrlSpy).toHaveBeenCalledWith(
          'http://test.host/gitlab-org/gitlab/-/blob/feature/test.js',
        );
      });

      describe('error handling', () => {
        const errorMessage = 'Custom error message';

        it('shows error message in modal when response contains error', async () => {
          mock.onPut().replyOnce(HTTP_STATUS_OK, { error: errorMessage });
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(errorMessage);
          expect(visitUrlSpy).not.toHaveBeenCalled();
        });

        it('shows error message in modal when request fails', async () => {
          mock.onPut().replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY, { message: errorMessage });
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(errorMessage);
        });

        it('shows customized error message, when generic 403 error is returned from backend', async () => {
          mock.onPut().replyOnce(HTTP_STATUS_FORBIDDEN, { message: 'Access denied' });
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(
            'An error occurred editing the blob',
          );
          expect(visitUrlSpy).not.toHaveBeenCalled();
        });

        it('clears error on successful submission', async () => {
          mock.onPut().replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY);
          await submitForm();

          // Verify error is set first
          expect(findCommitChangesModal().props('error')).toBe(
            'An error occurred editing the blob',
          );

          // Mock visitUrl to prevent actual navigation
          visitUrlSpy.mockImplementation(() => {});

          mock.onPut().replyOnce(HTTP_STATUS_OK, {
            branch: 'feature',
            file_path: 'test.js',
          });
          jest.spyOn(console, 'error').mockImplementation(() => {});

          // Submit the form again
          await submitForm();
          await nextTick();

          // The error should be cleared at the start of handleFormSubmit
          expect(findCommitChangesModal().props('error')).toBeNull();
          expect(visitUrlSpy).toHaveBeenCalledWith(
            'http://test.host/gitlab-org/gitlab/-/blob/feature/test.js',
          );
        });
      });

      describe('when renaming a file', () => {
        beforeEach(() => {
          // Mock the editor to return a different file path to trigger rename logic
          mockEditor.filepathFormMediator.$filenameInput.val.mockReturnValue('renamed_test.js');
          mockEditor.getOriginalFilePath.mockReturnValue('test.js');
          clickCommitChangesButton();
        });

        it('uses commits API when file path changes', async () => {
          mock.onPost().replyOnce(HTTP_STATUS_OK, {});

          await submitForm();

          expect(mock.history.post).toHaveLength(1);
          expect(mock.history.post[0].url).toBe('/api/v4/projects/123/repository/commits');

          const postData = JSON.parse(mock.history.post[0].data);
          expect(postData.branch).toBe('feature');
          expect(postData.commit_message).toBe('Test commit');
          expect(postData.actions).toHaveLength(1);
          expect(postData.actions[0]).toEqual({
            action: 'move',
            file_path: 'renamed_test.js',
            previous_path: 'test.js',
            content,
            last_commit_id: '782426692977b2cedb4452ee6501a404410f9b00',
          });
        });

        it('uses original_branch when branch_name is not provided', async () => {
          mock.onPost().replyOnce(HTTP_STATUS_OK, {});

          const formData = new FormData();
          formData.append('commit_message', 'Test commit');
          formData.append('original_branch', 'main');
          findCommitChangesModal().vm.$emit('submit-form', formData);
          await axios.waitForAll();

          const postData = JSON.parse(mock.history.post[0].data);
          expect(postData.branch).toBe('main');
        });

        it('redirects to renamed file on successful submission', async () => {
          mock.onPost().replyOnce(HTTP_STATUS_OK, {});

          await submitForm();

          expect(visitUrlSpy).toHaveBeenCalledWith(
            'http://test.host/gitlab-org/gitlab/-/blob/feature/renamed_test.js',
          );
        });

        it('handles error responses from commits API', async () => {
          const errorMessage = 'File rename failed';
          mock.onPost().replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY, {
            message: errorMessage,
          });

          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(errorMessage);
          expect(visitUrlSpy).not.toHaveBeenCalled();
        });

        it('handles error in response data from commits API', async () => {
          const errorMessage = 'Validation failed';
          mock.onPost().replyOnce(HTTP_STATUS_OK, {
            error: errorMessage,
          });

          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(errorMessage);
          expect(visitUrlSpy).not.toHaveBeenCalled();
        });
      });
    });

    describe('when blobEditRefactor is disabled', () => {
      beforeEach(() => {
        createWrapper({ glFeatures: { blobEditRefactor: false } });
        clickCommitChangesButton();
      });

      it('on submit, redirects to the updated file using controller', async () => {
        mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { filePath: '/update/path' });
        await submitForm();

        expect(mock.history.put).toHaveLength(1);
        expect(mock.history.put[0].url).toBe('/update');
        const putData = JSON.parse(mock.history.put[0].data);
        expect(putData.file).toBe(content);
        expect(visitUrlSpy).toHaveBeenCalledWith('/update/path');
      });

      describe('error handling', () => {
        const errorMessage = 'Controller error message';

        it('shows error message in modal when response contains error', async () => {
          mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { error: errorMessage });
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(errorMessage);
          expect(visitUrlSpy).not.toHaveBeenCalled();
        });

        it('shows error message in modal when request fails', async () => {
          mock
            .onPut('/update')
            .replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY, { error: errorMessage });
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(errorMessage);
        });

        it('shows error message when response does not contain filePath', async () => {
          mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { message: 'success' });
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(
            'An error occurred editing the blob',
          );
          expect(visitUrlSpy).not.toHaveBeenCalled();
        });

        it('clears error on successful submission', async () => {
          findCommitChangesButton().vm.$emit('click');
          await nextTick();

          mock.onPut('/update').replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY);
          await submitForm();

          expect(findCommitChangesModal().props('error')).toBe(
            'An error occurred editing the blob',
          );

          visitUrlSpy.mockImplementation(() => {});
          mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { filePath: '/update/path' });

          await submitForm();
          await nextTick();

          expect(findCommitChangesModal().props('error')).toBeNull();
        });
      });
    });
  });

  describe('for create blob', () => {
    beforeEach(() => {
      createWrapper({ action: 'create' });
    });

    it('shows confirmation message on cancel button', () => {
      expect(findCancelButton().attributes('data-confirm')).toBe(
        'Leave edit mode? All unsaved changes will be lost.',
      );
    });

    it('on submit, redirects to the new file', async () => {
      clickCommitChangesButton();
      mock.onPost('/update').reply(HTTP_STATUS_OK, { filePath: '/new/file' });
      await submitForm();

      expect(mock.history.post).toHaveLength(1);
      const putData = JSON.parse(mock.history.post[0].data);
      expect(putData.content).toBe(content);
      expect(visitUrlSpy).toHaveBeenCalledWith('/new/file');
    });
  });

  describe('validation', () => {
    it('toggles validation error when filename is empty', () => {
      mockEditor.filepathFormMediator.$filenameInput.val.mockReturnValue(null);
      createWrapper();
      clickCommitChangesButton();

      expect(mockEditor.filepathFormMediator.toggleValidationError).toHaveBeenCalledWith(true);
    });
  });
});
