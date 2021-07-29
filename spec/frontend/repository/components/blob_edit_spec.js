import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlobEdit from '~/repository/components/blob_edit.vue';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';

const DEFAULT_PROPS = {
  editPath: 'some_file.js/edit',
  webIdePath: 'some_file.js/ide/edit',
  showEditButton: true,
};

describe('BlobEdit component', () => {
  let wrapper;

  const createComponent = (consolidatedEditButton = false, props = {}) => {
    wrapper = shallowMount(BlobEdit, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        glFeatures: {
          consolidatedEditButton,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findButtons = () => wrapper.findAll(GlButton);
  const findEditButton = () => wrapper.find('[data-testid="edit"]');
  const findWebIdeButton = () => wrapper.find('[data-testid="web-ide"]');
  const findWebIdeLink = () => wrapper.find(WebIdeLink);

  it('renders component', () => {
    createComponent();

    const { editPath, webIdePath } = DEFAULT_PROPS;

    expect(wrapper.props()).toMatchObject({
      editPath,
      webIdePath,
    });
  });

  it('renders both buttons', () => {
    createComponent();

    expect(findButtons()).toHaveLength(2);
  });

  it('renders the Edit button', () => {
    createComponent();

    expect(findEditButton().attributes('href')).toBe(DEFAULT_PROPS.editPath);
    expect(findEditButton().text()).toBe('Edit');
    expect(findEditButton()).not.toBeDisabled();
  });

  it('renders the Web IDE button', () => {
    createComponent();

    expect(findWebIdeButton().attributes('href')).toBe(DEFAULT_PROPS.webIdePath);
    expect(findWebIdeButton().text()).toBe('Web IDE');
    expect(findWebIdeButton()).not.toBeDisabled();
  });

  it('renders WebIdeLink component', () => {
    createComponent(true);

    const { editPath: editUrl, webIdePath: webIdeUrl } = DEFAULT_PROPS;

    expect(findWebIdeLink().props()).toMatchObject({
      editUrl,
      webIdeUrl,
      isBlob: true,
      showEditButton: true,
    });
  });

  describe('Without Edit button', () => {
    const showEditButton = false;

    it('renders WebIdeLink component without an edit button', () => {
      createComponent(true, { showEditButton });

      expect(findWebIdeLink().props()).toMatchObject({ showEditButton });
    });

    it('does not render an Edit button', () => {
      createComponent(false, { showEditButton });

      expect(findEditButton().exists()).toBe(false);
    });
  });
});
