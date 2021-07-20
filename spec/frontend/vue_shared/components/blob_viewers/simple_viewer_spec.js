import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { HIGHLIGHT_CLASS_NAME } from '~/vue_shared/components/blob_viewers/constants';
import SimpleViewer from '~/vue_shared/components/blob_viewers/simple_viewer.vue';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

describe('Blob Simple Viewer component', () => {
  let wrapper;
  const contentMock = `<span id="LC1">First</span>\n<span id="LC2">Second</span>\n<span id="LC3">Third</span>`;
  const blobHash = 'foo-bar';

  function createComponent(
    content = contentMock,
    isRawContent = false,
    isRefactorFlagEnabled = false,
  ) {
    wrapper = shallowMount(SimpleViewer, {
      provide: {
        blobHash,
        glFeatures: {
          refactorBlobViewer: isRefactorFlagEnabled,
        },
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

  describe('Vue refactoring to use Source Editor', () => {
    const findSourceEditor = () => wrapper.find(SourceEditor);

    it.each`
      doesRender    | condition                                          | isRawContent | isRefactorFlagEnabled
      ${'Does not'} | ${'rawContent is not specified'}                   | ${false}     | ${true}
      ${'Does not'} | ${'feature flag is disabled is not specified'}     | ${true}      | ${false}
      ${'Does not'} | ${'both, the FF and rawContent are not specified'} | ${false}     | ${false}
      ${'Does'}     | ${'both, the FF and rawContent are specified'}     | ${true}      | ${true}
    `(
      '$doesRender render Source Editor component in readonly mode when $condition',
      async ({ isRawContent, isRefactorFlagEnabled } = {}) => {
        createComponent('raw content', isRawContent, isRefactorFlagEnabled);
        await waitForPromises();

        if (isRawContent && isRefactorFlagEnabled) {
          expect(findSourceEditor().exists()).toBe(true);

          expect(findSourceEditor().props('value')).toBe('raw content');
          expect(findSourceEditor().props('fileName')).toBe('test.js');
          expect(findSourceEditor().props('editorOptions')).toEqual({ readOnly: true });
        } else {
          expect(findSourceEditor().exists()).toBe(false);
        }
      },
    );
  });
});
