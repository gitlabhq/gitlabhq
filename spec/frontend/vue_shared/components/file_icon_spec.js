import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { FILE_SYMLINK_MODE } from '~/vue_shared/constants';

describe('File Icon component', () => {
  let wrapper;
  const findSvgIcon = () => wrapper.find('svg');
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const getIconName = () =>
    findSvgIcon().find('use').element.getAttribute('href').replace(`${gon.sprite_file_icons}#`, '');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FileIcon, {
      propsData: { ...props },
    });
  };

  it('should render a span element and an icon', () => {
    createComponent({
      fileName: 'test.js',
    });

    expect(wrapper.element.tagName).toEqual('SPAN');
    expect(findSvgIcon().exists()).toBeDefined();
  });

  it.each`
    fileName        | iconName
    ${'index.js'}   | ${'javascript'}
    ${'test.png'}   | ${'image'}
    ${'test.PNG'}   | ${'image'}
    ${'.npmrc'}     | ${'npm'}
    ${'.Npmrc'}     | ${'file'}
    ${'webpack.js'} | ${'webpack'}
  `('should render a $iconName icon based on file ending', ({ fileName, iconName }) => {
    createComponent({ fileName });
    expect(getIconName()).toBe(iconName);
  });

  it('should render a standard folder icon', () => {
    createComponent({
      fileName: 'js',
      folder: true,
    });

    expect(findSvgIcon().exists()).toBe(false);
    expect(findGlIcon().classes()).toContain('folder-icon');
  });

  it('should render a loading icon', () => {
    createComponent({
      fileName: 'test.js',
      loading: true,
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('should add a special class and a size class', () => {
    const size = 120;
    createComponent({
      fileName: 'test.js',
      cssClasses: 'extraclasses',
      size,
    });
    const classes = findSvgIcon().classes();

    expect(classes).toContain(`s${size}`);
    expect(classes).toContain('extraclasses');
  });

  it('should render a symlink icon', () => {
    createComponent({
      fileName: 'anything',
      fileMode: FILE_SYMLINK_MODE,
    });

    expect(findSvgIcon().exists()).toBe(false);
    expect(findGlIcon().attributes('name')).toBe('symlink');
  });
});
