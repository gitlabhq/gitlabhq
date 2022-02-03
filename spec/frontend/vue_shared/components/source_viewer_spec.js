import hljs from 'highlight.js/lib/core';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer.vue';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('highlight.js/lib/core');
Vue.use(VueRouter);
const router = new VueRouter();

describe('Source Viewer component', () => {
  let wrapper;
  const language = 'javascript';
  const content = `// Some source code`;
  const DEFAULT_BLOB_DATA = { language, rawTextBlob: content };
  const highlightedContent = `<span data-testid='test-highlighted' id='LC1'>${content}</span><span id='LC2'></span>`;

  hljs.highlight.mockImplementation(() => ({ value: highlightedContent }));
  hljs.highlightAuto.mockImplementation(() => ({ value: highlightedContent }));

  const createComponent = async (props = { autoDetect: false }) => {
    wrapper = shallowMountExtended(SourceViewer, {
      router,
      propsData: { blob: { ...DEFAULT_BLOB_DATA }, ...props },
    });
    await waitForPromises();
  };

  const findLineNumbers = () => wrapper.findComponent(LineNumbers);
  const findHighlightedContent = () => wrapper.findByTestId('test-highlighted');
  const findFirstLine = () => wrapper.find('#LC1');

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  describe('highlight.js', () => {
    it('registers the language definition', async () => {
      const languageDefinition = await import(`highlight.js/lib/languages/${language}`);

      expect(hljs.registerLanguage).toHaveBeenCalledWith(language, languageDefinition.default);
    });

    it('highlights the content', () => {
      expect(hljs.highlight).toHaveBeenCalledWith(content, { language });
    });

    describe('auto-detect enabled', () => {
      beforeEach(() => createComponent({ autoDetect: true }));

      it('highlights the content with auto-detection', () => {
        expect(hljs.highlightAuto).toHaveBeenCalledWith(content);
      });
    });
  });

  describe('rendering', () => {
    it('renders Line Numbers', () => {
      expect(findLineNumbers().props('lines')).toBe(1);
    });

    it('renders the highlighted content', () => {
      expect(findHighlightedContent().exists()).toBe(true);
    });
  });

  describe('selecting a line', () => {
    let firstLine;
    let firstLineElement;

    beforeEach(() => {
      firstLine = findFirstLine();
      firstLineElement = firstLine.element;

      jest.spyOn(firstLineElement, 'scrollIntoView');
      jest.spyOn(firstLineElement.classList, 'add');
      jest.spyOn(firstLineElement.classList, 'remove');
    });

    it('adds the highlight (hll) class', async () => {
      wrapper.vm.$router.push('#LC1');
      await nextTick();

      expect(firstLineElement.classList.add).toHaveBeenCalledWith('hll');
    });

    it('removes the highlight (hll) class from a previously highlighted line', async () => {
      wrapper.vm.$router.push('#LC2');
      await nextTick();

      expect(firstLineElement.classList.remove).toHaveBeenCalledWith('hll');
    });

    it('scrolls the line into view', () => {
      expect(firstLineElement.scrollIntoView).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center',
      });
    });
  });
});
