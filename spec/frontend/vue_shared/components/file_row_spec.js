import { GlIcon, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { file } from 'jest/ide/helpers';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileHeader from '~/vue_shared/components/file_row_header.vue';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

describe('File row component', () => {
  let wrapper;

  function createComponent(propsData, $router = undefined) {
    wrapper = shallowMountExtended(FileRow, {
      propsData,
      mocks: {
        $router,
      },
    });
  }

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const findFileButton = () => wrapper.findByTestId('file-row');

  it('renders name', () => {
    const fileName = 't4';
    createComponent({
      file: file(fileName),
      level: 0,
    });

    const name = wrapper.find('.file-row-name');

    expect(name.text().trim()).toEqual(fileName);
  });

  it('renders as button', () => {
    createComponent({
      file: file('t4'),
      level: 0,
    });
    expect(wrapper.find('button').exists()).toBe(true);
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

    expect(findFileButton().attributes('title')).toBe('path/to/file/with a very long folder name/');
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

    findFileButton().trigger('click');

    expect(wrapper.emitted('toggleTreeOpen')[0][0]).toEqual(fileName);
  });

  it('emits clickTree on tree click with correct options', () => {
    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    const fileName = 'folder';
    const filePath = 'path/to/folder';
    createComponent({ file: { ...file(fileName), type: 'tree', path: filePath }, level: 0 });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickTree')[0][0]).toEqual({ toggleClose: false });
    expect(trackEventSpy).toHaveBeenCalledWith(
      'click_file_tree_browser_on_repository_page',
      {},
      undefined,
    );
  });

  it('emits clickFile on blob click', () => {
    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    const fileName = 't3';
    const fileProp = {
      ...file(fileName),
      type: 'blob',
    };
    createComponent({
      file: fileProp,
      level: 1,
    });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickFile')[0][0]).toEqual(fileProp);
    expect(trackEventSpy).toHaveBeenCalledWith(
      'click_file_tree_browser_on_repository_page',
      {},
      undefined,
    );
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

  it('does not call scrollIntoView for Show more button', () => {
    const path = '/project/test.js';
    const router = { currentRoute: { path } };
    createComponent({ file: { path, isShowMore: true }, level: 0 }, router);

    expect(scrollIntoViewMock).not.toHaveBeenCalled();
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
    createComponent(
      {
        file: { ...file(fileName), url: `/${fileName}` },
        level: 0,
      },
      {
        currentRoute: {
          path: `/project/${fileName}`,
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
      fileClasses: '!gl-font-bold',
    });

    expect(wrapper.find('.file-row-name').classes()).toContain('!gl-font-bold');
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

  describe('Show more button', () => {
    const findShowMoreButton = () => wrapper.findComponent(GlButton);

    it('renders show more button when file.isShowMore is true', () => {
      createComponent({ file: { isShowMore: true, loading: false }, level: 0 });

      const showMoreButton = findShowMoreButton();
      expect(showMoreButton.props('category')).toBe('tertiary');
      expect(showMoreButton.props('loading')).toBe(false);
      expect(showMoreButton.text().trim()).toBe('Show more');
    });

    it('emits showMore event when show more button is clicked', () => {
      createComponent({ file: { isShowMore: true, loading: false }, level: 0 });

      findShowMoreButton().vm.$emit('click');

      expect(wrapper.emitted('showMore')).toHaveLength(1);
    });

    it('shows loading state on show more button', () => {
      createComponent({ file: { isShowMore: true, loading: true }, level: 0 });

      expect(findShowMoreButton().props('loading')).toBe(true);
    });
  });

  describe('Tree toggle chevron button', () => {
    const findChevronButton = () => wrapper.findByTestId('tree-toggle-button');
    const folderPath = 'path/to/folder';
    const mockFile = { ...file(folderPath), type: 'tree', opened: false };

    beforeEach(() => {
      createComponent({
        file: mockFile,
        level: 0,
        showTreeToggle: true,
      });
    });

    it('renders chevron button with correct icon and text text', () => {
      expect(findChevronButton().props()).toMatchObject({
        category: 'tertiary',
        size: 'small',
        icon: 'chevron-right',
      });

      expect(findChevronButton().attributes('aria-label')).toBe('Expand path/to/folder directory');

      // Ensure correct icon and aria-label when folder is expanded
      createComponent({ file: { ...mockFile, opened: true }, level: 0, showTreeToggle: true });
      expect(findChevronButton().props('icon')).toBe('chevron-down');
      expect(findChevronButton().attributes('aria-label')).toBe(
        'Collapse path/to/folder directory',
      );
    });

    it('renders chevron button for trees and emits clickTree when clicked', () => {
      findChevronButton().vm.$emit('click', { stopPropagation: jest.fn() });

      expect(wrapper.emitted('clickTree')).toHaveLength(1);
    });

    it('does not render when showTreeToggle is false', () => {
      createComponent({
        file: mockFile,
        level: 0,
        showTreeToggle: false,
      });

      expect(findChevronButton().exists()).toBe(false);
    });
  });
});
