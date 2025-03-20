import { nextTick } from 'vue';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { blobControlsDataMock } from 'ee_else_ce_jest/repository/mock_data';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import BlobDeleteFileGroup from '~/repository/components/header_area/blob_delete_file_group.vue';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';

jest.mock('~/lib/utils/common_utils', () => ({
  isLoggedIn: jest.fn().mockReturnValue(true),
}));

const DEFAULT_PROPS = {
  currentRef: 'master',
  isEmptyRepository: false,
  isUsingLfs: true,
  userPermissions: { pushCode: true, createMergeRequestIn: true, forkProject: true },
};

const DEFAULT_INJECT = {
  selectedBranch: 'root-main-patch-07420',
  originalBranch: 'master',
  blobInfo: blobControlsDataMock.repository.blobs.nodes[0],
};

describe('BlobDeleteFileGroup component', () => {
  let wrapper;
  let showDeleteBlobModalMock;

  const createComponent = async ({ props = {}, inject = {} } = {}) => {
    showDeleteBlobModalMock = jest.fn();

    const DeleteBlobModalStub = stubComponent(CommitChangesModal, {
      methods: {
        show: showDeleteBlobModalMock,
      },
    });

    wrapper = mountExtended(BlobDeleteFileGroup, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        ...DEFAULT_INJECT,
        ...inject,
      },
      stubs: {
        CommitChangesModal: DeleteBlobModalStub,
      },
    });
    await waitForPromises();
  };

  const findDeleteItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findDeleteBlobModal = () => wrapper.findComponent(CommitChangesModal);
  const findForkSuggestionModal = () => wrapper.findComponent(ForkSuggestionModal);

  beforeEach(async () => {
    await createComponent();
  });

  it('renders component', () => {
    expect(wrapper.props()).toMatchObject({
      currentRef: 'master',
      isEmptyRepository: false,
      isUsingLfs: true,
      userPermissions: { pushCode: true },
    });
  });

  describe('dropdown item', () => {
    it('renders the delete item', () => {
      expect(findDeleteItem().exists()).toBe(true);
    });

    it('triggers the DeleteBlobModal from the delete item', () => {
      findDeleteItem().vm.$emit('action');

      expect(showDeleteBlobModalMock).toHaveBeenCalled();
    });

    describe('when user cannot modify blob', () => {
      beforeEach(async () => {
        await createComponent({
          props: {
            isUsingLfs: false,
            userPermissions: { pushCode: false, createMergeRequestIn: true, forkProject: true },
          },
          inject: {
            blobInfo: {
              ...blobControlsDataMock.repository.blobs.nodes[0],
              canModifyBlob: false,
              canModifyBlobWithWebIde: false,
            },
          },
        });
      });

      it('does not trigger the DeleteBlobModal from the delete item', () => {
        findDeleteItem().vm.$emit('action');

        expect(showDeleteBlobModalMock).not.toHaveBeenCalled();
      });

      it('changes ForkSuggestionModal visibility', async () => {
        findDeleteItem().vm.$emit('action');
        await nextTick();

        expect(findForkSuggestionModal().props('visible')).toBe(true);
      });
    });
  });

  it('renders ForkSuggestionModal', () => {
    expect(findForkSuggestionModal().props()).toMatchObject({
      forkPath: 'fork/view/path',
    });
  });

  it('renders DeleteBlobModal', () => {
    expect(findDeleteBlobModal().props()).toMatchObject({
      commitMessage: 'Delete file.js',
      targetBranch: 'root-main-patch-07420',
      originalBranch: 'master',
      canPushCode: true,
      emptyRepo: false,
      isUsingLfs: true,
    });

    expect(findDeleteItem().props('item')).toMatchObject({
      extraAttrs: { disabled: false },
    });
  });
});
