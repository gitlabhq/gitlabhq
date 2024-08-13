import hljsCore from 'highlight.js/lib/core';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import { ROUGE_TO_HLJS_LANGUAGE_MAP } from '~/vue_shared/components/source_viewer/constants';
import { highlightContent } from '~/highlight_js';

jest.mock('highlight.js/lib/core');
jest.mock('~/content_editor/services/highlight_js_language_loader');

describe('highlightContent', () => {
  const mockHljsInstance = {
    registerLanguage: jest.fn(),
    addPlugin: jest.fn(),
    highlight: jest.fn(),
    getLanguage: jest.fn(),
  };

  beforeEach(() => {
    hljsCore.newInstance.mockReturnValue(mockHljsInstance);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('should highlight content with a known language', async () => {
    const lang = 'ruby';
    const rawContent = 'puts "Hello, world!"';
    const plugins = [];
    const hljsLanguage = 'ruby';

    ROUGE_TO_HLJS_LANGUAGE_MAP[lang.toLowerCase()] = hljsLanguage;

    const mockLanguageDefinition = { default: jest.fn(), contains: [] };
    languageLoader[hljsLanguage] = jest.fn().mockResolvedValue(mockLanguageDefinition);
    mockHljsInstance.highlight.mockReturnValue({
      value: '<span class="hljs-keyword">puts</span> "Hello, world!"',
    });
    mockHljsInstance.getLanguage.mockReturnValue(mockLanguageDefinition);

    const result = await highlightContent(lang, rawContent, plugins);

    expect(languageLoader[hljsLanguage]).toHaveBeenCalled();
    expect(mockHljsInstance.registerLanguage).toHaveBeenCalledWith(
      hljsLanguage,
      mockLanguageDefinition.default,
    );
    expect(mockHljsInstance.highlight).toHaveBeenCalledWith(rawContent, { language: hljsLanguage });
    expect(result).toBe('<span class="hljs-keyword">puts</span> "Hello, world!"');
  });

  it('should return undefined for an unknown language', async () => {
    const lang = 'unknownLanguage';
    const rawContent = 'some content';
    const plugins = [];

    ROUGE_TO_HLJS_LANGUAGE_MAP[lang.toLowerCase()] = undefined;

    const result = await highlightContent(lang, rawContent, plugins);

    expect(result).toBeUndefined();
  });
});
