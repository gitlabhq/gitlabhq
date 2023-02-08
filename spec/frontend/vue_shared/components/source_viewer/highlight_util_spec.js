import hljs from 'highlight.js';
import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import { highlight } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import { LINES_PER_CHUNK, NEWLINE } from '~/vue_shared/components/source_viewer/constants';

jest.mock('highlight.js', () => ({
  highlight: jest.fn().mockReturnValue({ value: 'highlighted content' }),
}));

jest.mock('~/vue_shared/components/source_viewer/plugins/index', () => ({
  registerPlugins: jest.fn(),
}));

const fileType = 'text';
const rawContent = 'function test() { return true }; \n // newline';
const highlightedContent = 'highlighted content';
const language = 'javascript';

describe('Highlight utility', () => {
  beforeEach(() => highlight(fileType, rawContent, language));

  it('registers the plugins', () => {
    expect(registerPlugins).toHaveBeenCalled();
  });

  it('highlights the content', () => {
    expect(hljs.highlight).toHaveBeenCalledWith(rawContent, { language });
  });

  it('splits the content into chunks', () => {
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

    expect(highlight(fileType, contentArray.join(NEWLINE), language)).toEqual(
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

  it('does not return a result', () => {
    expect(highlight(fileType, rawContent, unsupportedLanguage)).toBe(undefined);
  });
});
