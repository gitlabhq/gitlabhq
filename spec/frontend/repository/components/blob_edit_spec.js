import { shallowMount } from '@vue/test-utils';
import BlobEdit from '~/repository/components/blob_edit.vue';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';

const DEFAULT_PROPS = {
  editPath: 'some_file.js/edit',
  webIdePath: 'some_file.js/ide/edit',
  showEditButton: true,
  needsToFork: false,
};

describe('BlobEdit component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BlobEdit, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findEditButton = () => wrapper.find('[data-testid="edit"]');
  const findWebIdeLink = () => wrapper.find(WebIdeLink);

  it('renders component', () => {
    createComponent();

    const { editPath, webIdePath } = DEFAULT_PROPS;

    expect(wrapper.props()).toMatchObject({
      editPath,
      webIdePath,
    });
  });

  it('renders WebIdeLink component', () => {
    createComponent();

    const { editPath: editUrl, webIdePath: webIdeUrl, needsToFork } = DEFAULT_PROPS;

    expect(findWebIdeLink().props()).toMatchObject({
      editUrl,
      webIdeUrl,
      isBlob: true,
      showEditButton: true,
      needsToFork,
    });
  });

  describe('Without Edit button', () => {
    const showEditButton = false;

    it('renders WebIdeLink component without an edit button', () => {
      createComponent({ showEditButton });

      expect(findWebIdeLink().props()).toMatchObject({ showEditButton });
    });

    it('does not render an Edit button', () => {
      createComponent({ showEditButton });

      expect(findEditButton().exists()).toBe(false);
    });
  });
});
