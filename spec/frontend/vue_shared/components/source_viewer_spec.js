import hljs from 'highlight.js/lib/core';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer.vue';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('highlight.js/lib/core');

describe('Source Viewer component', () => {
  let wrapper;
  const content = `// Some source code`;
  const highlightedContent = `<span data-testid='test-highlighted'>${content}</span>`;
  const language = 'javascript';

  hljs.highlight.mockImplementation(() => ({ value: highlightedContent }));
  hljs.highlightAuto.mockImplementation(() => ({ value: highlightedContent }));

  const createComponent = async (props = {}) => {
    wrapper = shallowMountExtended(SourceViewer, { propsData: { content, language, ...props } });
    await waitForPromises();
  };

  const findLineNumbers = () => wrapper.findComponent(LineNumbers);
  const findHighlightedContent = () => wrapper.findByTestId('test-highlighted');

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
});
