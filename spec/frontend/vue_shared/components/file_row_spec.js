import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { file } from 'jest/ide/helpers';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileHeader from '~/vue_shared/components/file_row_header.vue';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

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

  it('emits toggleTreeOpen on tree click', () => {
    const fileName = 't3';
    createComponent({
      file: {
        ...file(fileName),
        type: 'tree',
      },
      level: 0,
    });

    wrapper.element.click();

    expect(wrapper.emitted('toggleTreeOpen')[0][0]).toEqual(fileName);
  });

  it('emits clickFile on blob click', () => {
    const fileName = 't3';
    const fileProp = {
      ...file(fileName),
      type: 'blob',
    };
    createComponent({
      file: fileProp,
      level: 1,
    });

    wrapper.element.click();

    expect(wrapper.emitted('clickFile')[0][0]).toEqual(fileProp);
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

    wrapper.setProps({
      file: { ...wrapper.props('file'), active: true },
    });

    return nextTick().then(() => {
      expect(scrollIntoViewMock).toHaveBeenCalled();
    });
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

    expect(wrapper.findComponent(FileHeader).exists()).toBe(true);
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

    expect(wrapper.findComponent(FileIcon).props('submodule')).toBe(submodule);
  });

  it('renders link icon', () => {
    createComponent({
      file: {
        ...file(),
        linked: true,
      },
      level: 0,
    });

    expect(wrapper.findComponent(GlIcon).props('name')).toBe('link');
  });
});
