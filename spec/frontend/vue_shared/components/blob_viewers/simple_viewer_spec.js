import { shallowMount } from '@vue/test-utils';
import SimpleViewer from '~/vue_shared/components/blob_viewers/simple_viewer.vue';
import { HIGHLIGHT_CLASS_NAME } from '~/vue_shared/components/blob_viewers/constants';

describe('Blob Simple Viewer component', () => {
  let wrapper;
  const contentMock = `<span id="LC1">First</span>\n<span id="LC2">Second</span>\n<span id="LC3">Third</span>`;
  const blobHash = 'foo-bar';

  function createComponent(content = contentMock) {
    wrapper = shallowMount(SimpleViewer, {
      provide: {
        blobHash,
      },
      propsData: {
        content,
        type: 'text',
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
});
