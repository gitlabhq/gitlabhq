import hljs from 'highlight.js/lib/core';
import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import { highlight } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import { LINES_PER_CHUNK, NEWLINE } from '~/vue_shared/components/source_viewer/constants';

jest.mock('highlight.js/lib/core', () => ({
  highlight: jest.fn().mockReturnValue({ value: 'highlighted content' }),
  registerLanguage: jest.fn(),
  getLanguage: jest.fn(),
}));

jest.mock('~/vue_shared/components/source_viewer/plugins/index', () => ({
  registerPlugins: jest.fn(),
}));

const fileType = 'text';
const rawContent = 'function test() { return true }; \n // newline';
const highlightedContent = 'highlighted content';
const language = 'json';

describe('Highlight utility', () => {
  beforeEach(() => highlight(fileType, rawContent, language));

  it('registers the language', () => {
    expect(hljs.registerLanguage).toHaveBeenCalledWith(language, expect.any(Function));
  });

  it('registers the plugins', () => {
    expect(registerPlugins).toHaveBeenCalled();
  });

  describe('sub-languages', () => {
    const languageDefinition = {
      subLanguage: 'xml',
      contains: [{ subLanguage: 'javascript' }, { subLanguage: 'typescript' }],
    };

    beforeEach(async () => {
      jest.spyOn(hljs, 'getLanguage').mockReturnValue(languageDefinition);
      await highlight(fileType, rawContent, language);
    });

    it('registers the primary sub-language', () => {
      expect(hljs.registerLanguage).toHaveBeenCalledWith(
        languageDefinition.subLanguage,
        expect.any(Function),
      );
    });

    it.each(languageDefinition.contains)(
      'registers the rest of the sub-languages',
      ({ subLanguage }) => {
        expect(hljs.registerLanguage).toHaveBeenCalledWith(subLanguage, expect.any(Function));
      },
    );
  });

  it('highlights the content', () => {
    expect(hljs.highlight).toHaveBeenCalledWith(rawContent, { language });
  });

  it('splits the content into chunks', async () => {
    const contentArray = Array.from({ length: 140 }, () => 'newline'); // simulate 140 lines of code

    const chunks = [
      {
        language,
        highlightedContent,
        rawContent: contentArray.slice(0, 70).join(NEWLINE), // first 70 lines
        startingFrom: 0,
        totalLines: LINES_PER_CHUNK,
      },
      {
        language,
        highlightedContent: '',
        rawContent: contentArray.slice(70, 140).join(NEWLINE), // last 70 lines
        startingFrom: 70,
        totalLines: LINES_PER_CHUNK,
      },
    ];

    expect(await highlight(fileType, contentArray.join(NEWLINE), language)).toEqual(
      expect.arrayContaining(chunks),
    );
  });
});

describe('unsupported languages', () => {
  const unsupportedLanguage = 'some_unsupported_language';

  beforeEach(() => highlight(fileType, rawContent, unsupportedLanguage));

  it('does not register plugins', () => {
    expect(registerPlugins).not.toHaveBeenCalled();
  });

  it('does not attempt to highlight the content', () => {
    expect(hljs.highlight).not.toHaveBeenCalled();
  });

  it('does not return a result', async () => {
    expect(await highlight(fileType, rawContent, unsupportedLanguage)).toBe(undefined);
  });
});
