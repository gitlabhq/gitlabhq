import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import BlobEditHeader from '~/repository/pages/blob_edit_header.vue';
import { stubComponent } from 'helpers/stub_component';

describe('BlobEditHeader', () => {
  let wrapper;
  const mockEditor = {
    getFileContent: jest.fn().mockReturnValue('test content'),
    filepathFormMediator: { $filenameInput: { val: jest.fn().mockReturnValue('.gitignore') } },
  };

  const createWrapper = () => {
    return shallowMountExtended(BlobEditHeader, {
      provide: {
        editor: mockEditor,
        updatePath: '/update',
        cancelPath: '/cancel',
        originalBranch: 'main',
        targetBranch: 'feature',
        blobName: 'test.js',
        canPushCode: true,
        canPushToBranch: true,
        emptyRepo: false,
        isUsingLfs: false,
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
    wrapper = createWrapper();
  });

  const findTitle = () => wrapper.find('h1');
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findCommitChangesModal = () => wrapper.findComponent(CommitChangesModal);
  const findCommitChangesButton = () => wrapper.findByTestId('blob-edit-header-commit-button');

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
      actionPath: '/update',
      canPushCode: true,
      canPushToBranch: true,
      commitMessage: 'Edit test.js',
      emptyRepo: false,
      fileContent: 'test content',
      filePath: '.gitignore',
      isUsingLfs: false,
      method: 'put',
      modalId: 'update-modal3',
      originalBranch: 'main',
      targetBranch: 'feature',
      isEdit: true,
      branchAllowsCollaboration: false,
      lastCommitSha: '782426692977b2cedb4452ee6501a404410f9b00',
    });
  });
});
