import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { file } from 'jest/ide/helpers';

import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

describe('File row component', () => {
  let wrapper;

  function createComponent(propsData, router) {
    wrapper = shallowMountExtended(FileRow, {
      propsData,
      router,
      stubs: {
        GlTruncate: {
          template: '<div>{{ text }}</div>',
          props: ['text'],
        },
      },
    });
  }

  const findFileRowContainer = () => wrapper.findByTestId('file-row-container');
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

  it('emits clickTree on tree click', () => {
    const fileName = 't3';
    createComponent({
      file: {
        ...file(fileName),
        type: 'tree',
      },
      level: 0,
    });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickTree')).toHaveLength(1);
  });

  it('emits clickRow on tree click', () => {
    const fileName = 'folder';
    const filePath = 'path/to/folder';
    createComponent({ file: { ...file(fileName), type: 'tree', path: filePath }, level: 0 });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickRow')).toHaveLength(1);
    expect(wrapper.emitted('clickTree')).toHaveLength(1);
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

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickFile')).toHaveLength(1);
  });

  it('emits clickRow event on blob click', () => {
    const fileName = 'test.txt';
    createComponent({
      file: {
        ...file(fileName),
        type: 'blob',
      },
      level: 0,
    });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickRow')).toHaveLength(1);
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

    expect(wrapper.attributes('title')).toBe('app/assets');
    expect(wrapper.text()).toBe('app/assets');
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

  describe('rovingTabindex prop', () => {
    it('sets tabindex to 0 by default', () => {
      createComponent({
        file: file('test.txt'),
        level: 0,
        rovingTabindex: false,
      });

      expect(findFileButton().attributes('tabindex')).toBe('0');
    });

    it('sets tabindex to -1 when rovingTabindex is true', () => {
      createComponent({
        file: file('test.txt'),
        level: 0,
        rovingTabindex: true,
      });

      expect(findFileButton().attributes('tabindex')).toBe('-1');
    });
  });

  it('emits clickSubmodule for submodules', () => {
    createComponent({
      file: { ...file('sub'), submodule: true, webUrl: 'https://ext.com' },
      level: 0,
    });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickSubmodule')).toHaveLength(1);
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

    it('aligns the chevron icon correctly with indentation line', () => {
      expect(findFileRowContainer().classes()).toContain('before:!gl-left-[calc(0.75rem-0.5px)]');
    });

    it('does not apply alignment class when showTreeToggle is false', () => {
      createComponent({ file: mockFile, level: 0, showTreeToggle: false });

      expect(findFileRowContainer().classes()).not.toContain(
        'before:!gl-left-[calc(0.75rem-0.5px)]',
      );
    });

    it('renders chevron button for trees and emits toggleTree when clicked', () => {
      findChevronButton().vm.$emit('click', { stopPropagation: jest.fn() });

      expect(wrapper.emitted('toggleTree')).toHaveLength(1);
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

  it('renders as button element when file does not have href', () => {
    createComponent({
      file: file('test.rb'),
      level: 0,
    });

    expect(findFileButton().element.tagName).toBe('BUTTON');
    expect(findFileButton().attributes('href')).toBeUndefined();
  });

  it('renders as link when file has href', () => {
    createComponent({
      file: {
        name: 'Readme.md',
        href: '/gitlab-org/gitlab/-/tree/readme.md',
      },
      level: 0,
    });

    expect(findFileButton().element.tagName).toBe('A');
    expect(findFileButton().attributes('href')).toBe('/gitlab-org/gitlab/-/tree/readme.md');
  });

  it('prevents default when clicking link when file has href', () => {
    createComponent({
      file: {
        name: 'Readme.md',
        href: '/gitlab-org/gitlab/-/tree/readme.md',
      },
      level: 0,
    });

    const event = new MouseEvent('click', { bubbles: true, cancelable: true });
    const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

    findFileButton().element.dispatchEvent(event);

    expect(preventDefaultSpy).toHaveBeenCalled();
  });

  it('emits clickRow and clickFile when clicking blob', () => {
    createComponent({
      file: {
        ...file('test.rb'),
        type: 'blob',
      },
      level: 0,
    });

    findFileButton().trigger('click');

    expect(wrapper.emitted('clickRow')).toHaveLength(1);
    expect(wrapper.emitted('clickFile')).toHaveLength(1);
  });
});
