import { ROUGE_TO_HLJS_LANGUAGE_MAP } from '~/vue_shared/components/source_viewer/constants';
import {
  highlight,
  splitIntoChunks,
} from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import { highlightContent } from '~/highlight_js';

jest.mock('~/highlight_js');

describe('highlight', () => {
  const fileType = 'javascript';
  const rawContent = 'const a = 1;\nconst b = 2;\n';
  const lang = 'javascript';
  const highlightedContent =
    '<span class="hljs-keyword">const</span> a = 1;\n<span class="hljs-keyword">const</span> b = 2;\n';

  beforeEach(() => {
    ROUGE_TO_HLJS_LANGUAGE_MAP[lang.toLowerCase()] = lang;
    highlightContent.mockResolvedValue(highlightedContent);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('should highlight content and split into chunks', async () => {
    const expectedChunks = [
      {
        highlightedContent,
        rawContent,
        totalLines: 3,
        startingFrom: 0,
        language: lang,
      },
    ];
    const result = await highlight(fileType, rawContent, lang);

    expect(highlightContent).toHaveBeenCalledWith(lang, rawContent, expect.any(Array));
    expect(result).toEqual(expectedChunks);
  });

  it('should return undefined for an unknown language', async () => {
    ROUGE_TO_HLJS_LANGUAGE_MAP[lang.toLowerCase()] = undefined;
    const result = await highlight(fileType, rawContent, lang);

    expect(result).toBeUndefined();
  });
});

describe('splitIntoChunks', () => {
  it('should split content into chunks', () => {
    const language = 'javascript';
    const rawContent = 'const a = 1;\nconst b = 2;\nconst c = 3;\nconst d = 4;\n';
    const highlightedContent =
      '<span class="hljs-keyword">const</span> a = 1;\n<span class="hljs-keyword">const</span> b = 2;\n<span class="hljs-keyword">const</span> c = 3;\n<span class="hljs-keyword">const</span> d = 4;\n';

    const expectedChunks = [
      {
        highlightedContent:
          '<span class="hljs-keyword">const</span> a = 1;\n' +
          '<span class="hljs-keyword">const</span> b = 2;\n' +
          '<span class="hljs-keyword">const</span> c = 3;\n' +
          '<span class="hljs-keyword">const</span> d = 4;\n',
        rawContent: 'const a = 1;\nconst b = 2;\nconst c = 3;\nconst d = 4;\n',
        totalLines: 5,
        startingFrom: 0,
        language: 'javascript',
      },
    ];
    const result = splitIntoChunks(language, rawContent, highlightedContent);
    expect(result).toEqual(expectedChunks);
  });
});
