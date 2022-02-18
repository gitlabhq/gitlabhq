import hljs from 'highlight.js/lib/core';
import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import { ROUGE_TO_HLJS_LANGUAGE_MAP } from '~/vue_shared/components/source_viewer/constants';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('highlight.js/lib/core');
Vue.use(VueRouter);
const router = new VueRouter();

describe('Source Viewer component', () => {
  let wrapper;
  const language = 'docker';
  const mappedLanguage = ROUGE_TO_HLJS_LANGUAGE_MAP[language];
  const content = `// Some source code`;
  const DEFAULT_BLOB_DATA = { language, rawTextBlob: content };
  const highlightedContent = `<span data-testid='test-highlighted' id='LC1'>${content}</span><span id='LC2'></span>`;

  const createComponent = async (blob = {}) => {
    wrapper = shallowMountExtended(SourceViewer, {
      router,
      propsData: { blob: { ...DEFAULT_BLOB_DATA, ...blob } },
    });
    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLineNumbers = () => wrapper.findComponent(LineNumbers);
  const findHighlightedContent = () => wrapper.findByTestId('test-highlighted');
  const findFirstLine = () => wrapper.find('#LC1');

  beforeEach(() => {
    hljs.highlight.mockImplementation(() => ({ value: highlightedContent }));
    hljs.highlightAuto.mockImplementation(() => ({ value: highlightedContent }));

    return createComponent();
  });

  afterEach(() => wrapper.destroy());

  describe('highlight.js', () => {
    it('registers the language definition', async () => {
      const languageDefinition = await import(`highlight.js/lib/languages/${mappedLanguage}`);

      expect(hljs.registerLanguage).toHaveBeenCalledWith(
        mappedLanguage,
        languageDefinition.default,
      );
    });

    it('highlights the content', () => {
      expect(hljs.highlight).toHaveBeenCalledWith(content, { language: mappedLanguage });
    });

    describe('auto-detects if a language cannot be loaded', () => {
      beforeEach(() => createComponent({ language: 'some_unknown_language' }));

      it('highlights the content with auto-detection', () => {
        expect(hljs.highlightAuto).toHaveBeenCalledWith(content);
      });
    });
  });

  describe('rendering', () => {
    it('renders a loading icon if no highlighted content is available yet', async () => {
      hljs.highlight.mockImplementation(() => ({ value: null }));
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });

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
