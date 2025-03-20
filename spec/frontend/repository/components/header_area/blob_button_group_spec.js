import { nextTick } from 'vue';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import BlobButtonGroup from '~/repository/components/header_area/blob_button_group.vue';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import { blobControlsDataMock, refMock } from 'ee_else_ce_jest/repository/mock_data';

jest.mock('~/lib/utils/common_utils', () => ({
  isLoggedIn: jest.fn().mockReturnValue(true),
}));

const DEFAULT_PROPS = {
  isUsingLfs: true,
  userPermissions: { pushCode: true, createMergeRequestIn: true, forkProject: true },
  currentRef: refMock,
  isReplaceDisabled: false,
};

const DEFAULT_INJECT = {
  selectedBranch: 'root-main-patch-07420',
  originalBranch: 'master',
  blobInfo: blobControlsDataMock.repository.blobs.nodes[0],
};

describe('BlobButtonGroup component', () => {
  let wrapper;

  let showUploadBlobModalMock;

  const createComponent = async ({ props = {}, inject = {} } = {}) => {
    showUploadBlobModalMock = jest.fn();

    const UploadBlobModalStub = stubComponent(UploadBlobModal, {
      methods: {
        show: showUploadBlobModalMock,
      },
    });

    wrapper = mountExtended(BlobButtonGroup, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        ...DEFAULT_INJECT,
        ...inject,
      },
      stubs: {
        UploadBlobModal: UploadBlobModalStub,
      },
    });
    await waitForPromises();
  };

  const findReplaceItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findForkSuggestionModal = () => wrapper.findComponent(ForkSuggestionModal);

  beforeEach(async () => {
    await createComponent();
  });

  it('renders component', () => {
    expect(wrapper.props()).toMatchObject({
      isUsingLfs: true,
      userPermissions: { pushCode: true, createMergeRequestIn: true, forkProject: true },
      currentRef: 'default-ref',
      isReplaceDisabled: false,
    });
  });

  describe('dropdown items', () => {
    it('renders the replace item', () => {
      expect(wrapper.findAllComponents(GlDisclosureDropdownItem)).toHaveLength(1);
      expect(findReplaceItem().exists()).toBe(true);
    });

    it('triggers the UploadBlobModal from the replace item', () => {
      findReplaceItem().vm.$emit('action');

      expect(showUploadBlobModalMock).toHaveBeenCalled();
    });

    describe('when user cannot modify blob', () => {
      beforeEach(async () => {
        await createComponent({
          props: { isUsingLfs: false },
          inject: {
            blobInfo: {
              ...blobControlsDataMock.repository.blobs.nodes[0],
              canModifyBlob: false,
              canModifyBlobWithWebIde: false,
            },
          },
        });
      });

      it('does not trigger the UploadBlobModal from the replace item', () => {
        findReplaceItem().vm.$emit('action');

        expect(showUploadBlobModalMock).not.toHaveBeenCalled();
      });

      it('triggers ForkSuggestionModal from the replace item', async () => {
        findReplaceItem().vm.$emit('action');
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

  it('should not disable replace button', () => {
    expect(findReplaceItem().props('item')).toMatchObject({
      extraAttrs: { disabled: false },
    });
  });

  it('renders UploadBlobModal', () => {
    expect(findUploadBlobModal().props()).toMatchObject({
      commitMessage: 'Replace file.js',
      targetBranch: 'root-main-patch-07420',
      originalBranch: 'master',
      canPushCode: true,
      path: 'some/file.js',
      replacePath: 'some/replace/file.js',
    });
  });
});
