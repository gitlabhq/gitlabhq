import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('File Icon component', () => {
  let wrapper;
  const findIcon = () => wrapper.find('svg');
  const getIconName = () =>
    findIcon()
      .find('use')
      .element.getAttribute('xlink:href')
      .replace(`${gon.sprite_file_icons}#`, '');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FileIcon, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a span element and an icon', () => {
    createComponent({
      fileName: 'test.js',
    });

    expect(wrapper.element.tagName).toEqual('SPAN');
    expect(findIcon().exists()).toBeDefined();
  });

  it.each`
    fileName        | iconName
    ${'test.js'}    | ${'javascript'}
    ${'test.png'}   | ${'image'}
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

    expect(findIcon().exists()).toBe(false);
    expect(wrapper.find(Icon).classes()).toContain('folder-icon');
  });

  it('should render a loading icon', () => {
    createComponent({
      fileName: 'test.js',
      loading: true,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('should add a special class and a size class', () => {
    const size = 120;
    createComponent({
      fileName: 'test.js',
      cssClasses: 'extraclasses',
      size,
    });

    expect(findIcon().classes()).toContain(`s${size}`);
    expect(findIcon().classes()).toContain('extraclasses');
  });
});
