import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { file } from 'jest/ide/helpers';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileHeader from '~/vue_shared/components/file_row_header.vue';

describe('File row component', () => {
  let wrapper;

  function createComponent(propsData, $router = undefined) {
    wrapper = shallowMount(FileRow, {
      propsData,
      mocks: {
        $router,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders name', () => {
    const fileName = 't4';
    createComponent({
      file: file(fileName),
      level: 0,
    });

    const name = wrapper.find('.file-row-name');

    expect(name.text().trim()).toEqual(fileName);
  });

  it('renders the full path as title', () => {
    const filePath = 'path/to/file/with a very long folder name/';
    const fileName = 'foo.txt';

    createComponent({
      file: {
        name: fileName,
        isHeader: false,
        tree: [
          {
            parentPath: filePath,
          },
        ],
      },
      level: 1,
    });

    expect(wrapper.element.title.trim()).toEqual('path/to/file/with a very long folder name/');
  });

  it('does not render a title attribute if no tree present', () => {
    createComponent({
      file: file('f1.txt'),
      level: 0,
    });

    expect(wrapper.element.title.trim()).toEqual('');
  });

  it('emits toggleTreeOpen on click', () => {
    const fileName = 't3';
    createComponent({
      file: {
        ...file(fileName),
        type: 'tree',
      },
      level: 0,
    });
    jest.spyOn(wrapper.vm, '$emit');

    wrapper.element.click();

    expect(wrapper.vm.$emit).toHaveBeenCalledWith('toggleTreeOpen', fileName);
  });

  it('calls scrollIntoView if made active', () => {
    createComponent({
      file: {
        ...file(),
        type: 'blob',
        active: false,
      },
      level: 0,
    });

    jest.spyOn(wrapper.vm, 'scrollIntoView');

    wrapper.setProps({
      file: { ...wrapper.props('file'), active: true },
    });

    return nextTick().then(() => {
      expect(wrapper.vm.scrollIntoView).toHaveBeenCalled();
    });
  });

  it('indents row based on level', () => {
    createComponent({
      file: file('t4'),
      level: 2,
    });

    expect(wrapper.find('.file-row-name').element.style.marginLeft).toBe('32px');
  });

  it('renders header for file', () => {
    createComponent({
      file: {
        isHeader: true,
        path: 'app/assets',
        tree: [],
      },
      level: 0,
    });

    expect(wrapper.find(FileHeader).exists()).toBe(true);
  });

  it('matches the current route against encoded file URL', () => {
    const fileName = 'with space';
    const rowFile = { ...file(fileName), url: `/${fileName}` };
    const routerPath = `/project/${escapeFileUrl(fileName)}`;
    createComponent(
      {
        file: rowFile,
        level: 0,
      },
      {
        currentRoute: {
          path: routerPath,
        },
      },
    );

    expect(wrapper.vm.hasUrlAtCurrentRoute()).toBe(true);
  });

  it('render with the correct file classes prop', () => {
    createComponent({
      file: {
        ...file(),
      },
      level: 0,
      fileClasses: 'font-weight-bold',
    });

    expect(wrapper.find('.file-row-name').classes()).toContain('font-weight-bold');
  });

  it('renders submodule icon', () => {
    const submodule = true;

    createComponent({
      file: {
        ...file(),
        submodule,
      },
      level: 0,
    });

    expect(wrapper.find(FileIcon).props('submodule')).toBe(submodule);
  });
});
