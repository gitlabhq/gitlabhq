import { mount } from '@vue/test-utils';
import { file } from 'jest/ide/helpers';
import ItemComponent from '~/vue_shared/components/file_finder/item.vue';

describe('File finder item spec', () => {
  let wrapper;

  const createComponent = ({ file: customFileFields = {}, ...otherProps } = {}) => {
    wrapper = mount(ItemComponent, {
      propsData: {
        file: {
          ...file(),
          name: 'test file',
          path: 'test/file',
          ...customFileFields,
        },
        focused: true,
        searchText: '',
        index: 0,
        ...otherProps,
      },
    });
  };

  it('renders file name & path', () => {
    createComponent();

    expect(wrapper.text()).toContain('test file');
    expect(wrapper.text()).toContain('test/file');
  });

  describe('focused', () => {
    it('adds is-focused class', () => {
      createComponent();

      expect(wrapper.classes()).toContain('is-focused');
    });

    it('does not have is-focused class when not focused', () => {
      createComponent({ focused: false });

      expect(wrapper.classes()).not.toContain('is-focused');
    });
  });

  describe('changed file icon', () => {
    it('does not render when not a changed or temp file', () => {
      createComponent();

      expect(wrapper.find('.diff-changed-stats').exists()).toBe(false);
    });

    it('renders when a changed file', () => {
      createComponent({ file: { changed: true } });

      expect(wrapper.find('.diff-changed-stats').exists()).toBe(true);
    });

    it('renders when a temp file', () => {
      createComponent({ file: { tempFile: true } });

      expect(wrapper.find('.diff-changed-stats').exists()).toBe(true);
    });
  });

  it('emits event when clicked', async () => {
    createComponent();

    await wrapper.find('*').trigger('click');

    expect(wrapper.emitted('click')[0]).toStrictEqual([wrapper.props('file')]);
  });

  describe('path', () => {
    const findChangedFilePath = () => wrapper.find('.diff-changed-file-path');

    it('highlights text', () => {
      createComponent({ searchText: 'file' });

      expect(findChangedFilePath().findAll('.highlighted')).toHaveLength(4);
    });

    it('adds ellipsis to long text', () => {
      const path = new Array(70)
        .fill()
        .map((_, i) => `${i}-`)
        .join('');

      createComponent({ searchText: 'file', file: { path } });

      expect(findChangedFilePath().text()).toBe(`...${path.substring(path.length - 60)}`);
    });
  });

  describe('name', () => {
    const findChangedFileName = () => wrapper.find('.diff-changed-file-name');

    it('highlights text', () => {
      createComponent({ searchText: 'file' });

      expect(findChangedFileName().findAll('.highlighted')).toHaveLength(4);
    });

    it('does not add ellipsis to long text', () => {
      const name = new Array(70)
        .fill()
        .map((_, i) => `${i}-`)
        .join('');

      createComponent({ searchText: 'file', file: { name } });

      expect(findChangedFileName().text()).not.toBe(`...${name.substring(name.length - 60)}`);
    });
  });
});
