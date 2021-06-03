import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlobHeaderEdit from '~/repository/components/blob_header_edit.vue';

const DEFAULT_PROPS = {
  editPath: 'some_file.js/edit',
  webIdePath: 'some_file.js/ide/edit',
};

describe('BlobHeaderEdit component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BlobHeaderEdit, {
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

  const findButtons = () => wrapper.findAll(GlButton);
  const findEditButton = () => findButtons().at(0);
  const findWebIdeButton = () => findButtons().at(1);

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
});
