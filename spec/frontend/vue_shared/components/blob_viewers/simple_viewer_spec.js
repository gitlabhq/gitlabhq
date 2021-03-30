import { shallowMount } from '@vue/test-utils';
import { HIGHLIGHT_CLASS_NAME } from '~/vue_shared/components/blob_viewers/constants';
import SimpleViewer from '~/vue_shared/components/blob_viewers/simple_viewer.vue';
import EditorLite from '~/vue_shared/components/editor_lite.vue';

describe('Blob Simple Viewer component', () => {
  let wrapper;
  const contentMock = `<span id="LC1">First</span>\n<span id="LC2">Second</span>\n<span id="LC3">Third</span>`;
  const blobHash = 'foo-bar';

  function createComponent(content = contentMock, isRawContent = false) {
    wrapper = shallowMount(SimpleViewer, {
      provide: {
        blobHash,
      },
      propsData: {
        content,
        type: 'text',
        fileName: 'test.js',
        isRawContent,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not fail if content is empty', () => {
    const spy = jest.spyOn(window.console, 'error');
    createComponent('');
    expect(spy).not.toHaveBeenCalled();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders exactly three lines', () => {
      expect(wrapper.findAll('.js-line-number')).toHaveLength(3);
    });

    it('renders the content without transformations', () => {
      expect(wrapper.html()).toContain(contentMock);
    });
  });

  describe('functionality', () => {
    const scrollIntoViewMock = jest.fn();
    HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

    beforeEach(() => {
      window.location.hash = '#LC2';
      createComponent();
    });

    afterEach(() => {
      window.location.hash = '';
    });

    it('scrolls to requested line when rendered', () => {
      const linetoBeHighlighted = wrapper.find('#LC2');
      expect(scrollIntoViewMock).toHaveBeenCalled();
      expect(wrapper.vm.highlightedLine).toBe(linetoBeHighlighted.element);
      expect(linetoBeHighlighted.classes()).toContain(HIGHLIGHT_CLASS_NAME);
    });

    it('switches highlighting when another line is selected', () => {
      const currentlyHighlighted = wrapper.find('#LC2');
      const hash = '#LC3';
      const linetoBeHighlighted = wrapper.find(hash);

      expect(wrapper.vm.highlightedLine).toBe(currentlyHighlighted.element);

      wrapper.vm.scrollToLine(hash);

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.highlightedLine).toBe(linetoBeHighlighted.element);
        expect(currentlyHighlighted.classes()).not.toContain(HIGHLIGHT_CLASS_NAME);
        expect(linetoBeHighlighted.classes()).toContain(HIGHLIGHT_CLASS_NAME);
      });
    });
  });

  describe('raw content', () => {
    const findEditorLite = () => wrapper.find(EditorLite);
    const isRawContent = true;

    it('uses the Editor Lite component in readonly mode when viewing raw content', () => {
      createComponent('raw content', isRawContent);

      expect(findEditorLite().exists()).toBe(true);
      expect(findEditorLite().props('value')).toBe('raw content');
      expect(findEditorLite().props('fileName')).toBe('test.js');
      expect(findEditorLite().props('editorOptions')).toEqual({ readOnly: true });
    });
  });
});
