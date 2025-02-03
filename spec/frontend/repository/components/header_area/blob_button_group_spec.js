import { GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { projectMock } from 'ee_else_ce_jest/repository/mock_data';
import projectInfoQuery from 'ee_else_ce/repository/queries/project_info.query.graphql';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobButtonGroup from '~/repository/components/header_area/blob_button_group.vue';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';
import { createAlert } from '~/alert';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils', () => ({
  isLoggedIn: jest.fn().mockReturnValue(true),
}));

const DEFAULT_PROPS = {
  name: 'some name',
  path: 'some/path',
  replacePath: 'some/replace/path',
  deletePath: 'some/delete/path',
  canPushToBranch: true,
  isEmptyRepository: false,
  projectPath: 'some/project/path',
  isUsingLfs: true,
};

const DEFAULT_INJECT = {
  targetBranch: 'master',
  originalBranch: 'master',
  canModifyBlob: true,
  canModifyBlobWithWebIde: true,
};

describe('BlobButtonGroup component', () => {
  let wrapper;
  let fakeApollo;

  let showUploadBlobModalMock;
  let showDeleteBlobModalMock;

  const projectInfoQueryMockResolver = jest
    .fn()
    .mockResolvedValue({ data: { project: projectMock } });
  const projectInfoQueryErrorResolver = jest.fn().mockRejectedValue(new Error('Request failed'));

  const createComponent = async ({
    props = {},
    projectInfoResolver = projectInfoQueryMockResolver,
    inject = {},
  } = {}) => {
    showUploadBlobModalMock = jest.fn();
    showDeleteBlobModalMock = jest.fn();

    const UploadBlobModalStub = stubComponent(UploadBlobModal, {
      methods: {
        show: showUploadBlobModalMock,
      },
    });
    const DeleteBlobModalStub = stubComponent(CommitChangesModal, {
      methods: {
        show: showDeleteBlobModalMock,
      },
    });

    fakeApollo = createMockApollo([[projectInfoQuery, projectInfoResolver]]);

    wrapper = mountExtended(BlobButtonGroup, {
      apolloProvider: fakeApollo,
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
        CommitChangesModal: DeleteBlobModalStub,
      },
    });
    await waitForPromises();
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => x.props('item').text === text);
  const findDeleteItem = () => findDropdownItemWithText('Delete');
  const findReplaceItem = () => findDropdownItemWithText('Replace');
  const findDeleteBlobModal = () => wrapper.findComponent(CommitChangesModal);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  it('renders component', () => {
    expect(wrapper.props()).toMatchObject({
      name: 'some name',
      path: 'some/path',
    });
  });

  it('creates an alert with the correct message, when projectInfo query fails', async () => {
    await createComponent({ projectInfoResolver: projectInfoQueryErrorResolver });

    expect(createAlert).toHaveBeenCalledWith({
      message: 'An error occurred while fetching lock information, please try again.',
    });
  });

  describe('dropdown items', () => {
    it('renders both the replace and delete item', () => {
      expect(wrapper.findAllComponents(GlDisclosureDropdownItem)).toHaveLength(2);
      expect(findReplaceItem().exists()).toBe(true);
      expect(findDeleteItem().exists()).toBe(true);
    });

    it('triggers the UploadBlobModal from the replace item', () => {
      findReplaceItem().vm.$emit('action');

      expect(showUploadBlobModalMock).toHaveBeenCalled();
    });

    it('triggers the CommitChangesModal from the delete item', () => {
      findDeleteItem().vm.$emit('action');

      expect(showDeleteBlobModalMock).toHaveBeenCalled();
    });

    describe('when user cannot modify blob', () => {
      beforeEach(async () => {
        await createComponent({
          props: { isUsingLfs: false },
          inject: { canModifyBlob: false, canModifyBlobWithWebIde: false },
        });
      });

      it('does not trigger the UploadBlobModal from the replace item', () => {
        findReplaceItem().vm.$emit('action');

        expect(findReplaceItem().props('item')).toMatchObject({
          extraAttrs: { disabled: true },
        });

        expect(showUploadBlobModalMock).not.toHaveBeenCalled();
        expect(wrapper.emitted().fork).toHaveLength(1);
      });

      it('does not trigger the DeleteBlobModal from the delete item', () => {
        findDeleteItem().vm.$emit('action');

        expect(findDeleteItem().props('item')).toMatchObject({
          extraAttrs: { disabled: true },
        });

        expect(showDeleteBlobModalMock).not.toHaveBeenCalled();
        expect(wrapper.emitted().fork).toHaveLength(1);
      });
    });
  });

  it('renders UploadBlobModal', () => {
    expect(findUploadBlobModal().props()).toMatchObject({
      commitMessage: 'Replace some name',
      targetBranch: 'master',
      originalBranch: 'master',
      canPushCode: true,
      path: 'some/path',
      replacePath: 'some/replace/path',
    });
  });

  it('renders CommitChangesModal for delete', () => {
    expect(findDeleteBlobModal().props()).toMatchObject({
      commitMessage: 'Delete some name',
      targetBranch: 'master',
      originalBranch: 'master',
      canPushCode: true,
      emptyRepo: false,
      isUsingLfs: true,
    });
  });
});
