import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { logError } from '~/lib/logger';

jest.mock('~/alert');
jest.mock('~/lib/logger');

describe('DeleteBlobModal', () => {
  let wrapper;
  let mock;
  let visitUrlSpy;

  const initialProps = {
    deletePath: '/delete/blob',
    modalId: 'Delete-blob',
    commitMessage: 'Delete File',
    targetBranch: 'some-target-branch',
    originalBranch: 'main',
    canPushCode: true,
    canPushToBranch: true,
    emptyRepo: false,
    isUsingLfs: false,
  };

  const createComponent = () => {
    wrapper = shallowMount(DeleteBlobModal, {
      propsData: {
        ...initialProps,
      },
      stubs: {
        CommitChangesModal,
      },
    });
  };

  const findCommitChangesModal = () => wrapper.findComponent(CommitChangesModal);
  const submitForm = async () => {
    findCommitChangesModal().vm.$emit('submit-form', new FormData());

    await axios.waitForAll();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl');

    createComponent();
  });

  afterEach(() => {
    mock.restore();
  });

  it('renders commit change modal with correct props', () => {
    expect(findCommitChangesModal().props()).toStrictEqual({
      branchAllowsCollaboration: false,
      canPushCode: true,
      canPushToBranch: true,
      commitMessage: 'Delete File',
      emptyRepo: false,
      error: null,
      isUsingLfs: false,
      loading: false,
      modalId: 'Delete-blob',
      originalBranch: 'main',
      targetBranch: 'some-target-branch',
      valid: true,
    });
  });

  describe('form submission', () => {
    it('handles successful request', async () => {
      mock.onPost(initialProps.deletePath).reply(HTTP_STATUS_OK, { filePath: 'blah' });

      await submitForm();

      expect(visitUrlSpy).toHaveBeenCalledWith('blah');
    });

    it('handles failed request', async () => {
      mock = new MockAdapter(axios);
      mock.onPost(initialProps.deletePath).timeout();

      await submitForm();

      const mockError = new Error('timeout of 0ms exceeded');

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to delete file! Please try again.',
        error: mockError,
      });
      expect(logError).toHaveBeenCalledWith(
        'Failed to delete file. See exception details for more information.',
        mockError,
      );
    });
  });
});
