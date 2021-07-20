import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const DEFAULT_PROPS = {
  name: 'some name',
  path: 'some/path',
  canPushCode: true,
  replacePath: 'some/replace/path',
  deletePath: 'some/delete/path',
  emptyRepo: false,
};

const DEFAULT_INJECT = {
  targetBranch: 'master',
  originalBranch: 'master',
};

describe('BlobButtonGroup component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BlobButtonGroup, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        ...DEFAULT_INJECT,
      },
      directives: {
        GlModal: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDeleteBlobModal = () => wrapper.findComponent(DeleteBlobModal);
  const findUploadBlobModal = () => wrapper.findComponent(UploadBlobModal);
  const findReplaceButton = () => wrapper.findAll(GlButton).at(0);

  it('renders component', () => {
    createComponent();

    const { name, path } = DEFAULT_PROPS;

    expect(wrapper.props()).toMatchObject({
      name,
      path,
    });
  });

  describe('buttons', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders both the replace and delete button', () => {
      expect(wrapper.findAll(GlButton)).toHaveLength(2);
    });

    it('renders the buttons in the correct order', () => {
      expect(wrapper.findAll(GlButton).at(0).text()).toBe('Replace');
      expect(wrapper.findAll(GlButton).at(1).text()).toBe('Delete');
    });

    it('triggers the UploadBlobModal from the replace button', () => {
      const { value } = getBinding(findReplaceButton().element, 'gl-modal');
      const modalId = findUploadBlobModal().props('modalId');

      expect(modalId).toEqual(value);
    });
  });

  it('renders UploadBlobModal', () => {
    createComponent();

    const { targetBranch, originalBranch } = DEFAULT_INJECT;
    const { name, path, canPushCode, replacePath } = DEFAULT_PROPS;
    const title = `Replace ${name}`;

    expect(findUploadBlobModal().props()).toMatchObject({
      modalTitle: title,
      commitMessage: title,
      targetBranch,
      originalBranch,
      canPushCode,
      path,
      replacePath,
      primaryBtnText: 'Replace file',
    });
  });

  it('renders DeleteBlobModel', () => {
    createComponent();

    const { targetBranch, originalBranch } = DEFAULT_INJECT;
    const { name, canPushCode, deletePath, emptyRepo } = DEFAULT_PROPS;
    const title = `Delete ${name}`;

    expect(findDeleteBlobModal().props()).toMatchObject({
      modalTitle: title,
      commitMessage: title,
      targetBranch,
      originalBranch,
      canPushCode,
      deletePath,
      emptyRepo,
    });
  });
});
