import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlButton } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import { HTTP_STATUS_OK, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import BlobEditHeader from '~/repository/pages/blob_edit_header.vue';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/alert');
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
    filepathFormMediator: { $filenameInput: { val: jest.fn().mockReturnValue('.gitignore') } },
  };

  const createWrapper = ({ action = 'update' } = {}) => {
    return shallowMountExtended(BlobEditHeader, {
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
      },
      stubs: {
        CommitChangesModal: stubComponent(CommitChangesModal, {
          methods: {
            show: jest.fn(),
          },
        }),
      },
    });
  };

  beforeEach(() => {
    visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl');
    mock = new MockAdapter(axios);
    wrapper = createWrapper();
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

  const submitForm = async () => {
    findCommitChangesModal().vm.$emit('submit-form', new FormData());

    await axios.waitForAll();
  };

  describe('for edit blob', () => {
    it('renders title with two buttons', () => {
      expect(findTitle().text()).toBe('Edit file');
      const buttons = findButtons();
      expect(buttons).toHaveLength(2);
      expect(buttons.at(0).text()).toBe('Cancel');
      expect(buttons.at(1).text()).toBe('Commit changes');
    });

    it('opens commit changes modal with correct props', async () => {
      findCommitChangesButton().vm.$emit('click');
      await nextTick();
      expect(mockEditor.getFileContent).toHaveBeenCalled();
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

    it('shows confirmation message on cancel button', () => {
      expect(findCancelButton().attributes('data-confirm')).toBe(
        'Leave edit mode? All unsaved changes will be lost.',
      );
    });

    it('on submit, redirects to the updated file', async () => {
      findCommitChangesButton().vm.$emit('click');

      mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { filePath: '/update/path' });
      await submitForm();

      expect(mock.history.put).toHaveLength(1);
      const putData = JSON.parse(mock.history.put[0].data);
      expect(putData.file).toBe(content);
      expect(visitUrlSpy).toHaveBeenCalledWith('/update/path');
    });

    describe('error handling', () => {
      const errorMessage = 'Custom error message';

      it('shows error message in modal when response contains error', async () => {
        mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { error: errorMessage });
        await submitForm();

        expect(findCommitChangesModal().props('error')).toBe(errorMessage);
        expect(visitUrlSpy).not.toHaveBeenCalled();
      });

      it('shows error message in modal when request fails', async () => {
        mock.onPut('/update').replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY, { error: errorMessage });
        await submitForm();

        expect(findCommitChangesModal().props('error')).toBe(errorMessage);
      });

      it('clears error on successful submission', async () => {
        mock.onPut('/update').replyOnce(HTTP_STATUS_UNPROCESSABLE_ENTITY);
        await submitForm();

        mock.onPut('/update').replyOnce(HTTP_STATUS_OK, { filePath: '/update/path' });
        jest.spyOn(console, 'error').mockImplementation(() => {});
        await submitForm();

        expect(findCommitChangesModal().props('error')).toBeNull();
      });
    });
  });

  describe('for create blob', () => {
    beforeEach(() => {
      wrapper = createWrapper({ action: 'create' });
    });

    it('renders title with two buttons', () => {
      expect(findTitle().text()).toBe('New file');
      const buttons = findButtons();
      expect(buttons).toHaveLength(2);
      expect(buttons.at(0).text()).toBe('Cancel');
      expect(buttons.at(1).text()).toBe('Commit changes');
    });

    it('opens commit changes modal with correct props', async () => {
      findCommitChangesButton().vm.$emit('click');
      await nextTick();
      expect(mockEditor.getFileContent).toHaveBeenCalled();
      expect(findCommitChangesModal().props()).toEqual({
        modalId: 'update-modal1',
        canPushCode: true,
        canPushToBranch: true,
        commitMessage: 'Add new file',
        originalBranch: 'main',
        targetBranch: 'feature',
        isUsingLfs: false,
        emptyRepo: false,
        branchAllowsCollaboration: false,
        loading: false,
        valid: true,
        error: null,
      });
    });

    it('shows confirmation message on cancel button', () => {
      expect(findCancelButton().attributes('data-confirm')).toBe(
        'Leave edit mode? All unsaved changes will be lost.',
      );
    });

    it('on submit, redirects to the new file', async () => {
      findCommitChangesButton().vm.$emit('click');

      mock.onPost('/update').reply(HTTP_STATUS_OK, { filePath: '/new/file' });
      await submitForm();

      expect(mock.history.post).toHaveLength(1);
      const putData = JSON.parse(mock.history.post[0].data);
      expect(putData.content).toBe(content);
      expect(visitUrlSpy).toHaveBeenCalledWith('/new/file');
    });
  });
});
