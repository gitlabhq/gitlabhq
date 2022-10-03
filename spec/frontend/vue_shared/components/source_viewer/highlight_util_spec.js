import hljs from 'highlight.js/lib/core';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import { highlight } from '~/vue_shared/components/source_viewer/workers/highlight_utils';

jest.mock('highlight.js/lib/core', () => ({
  highlight: jest.fn().mockReturnValue({}),
  registerLanguage: jest.fn(),
}));

jest.mock('~/content_editor/services/highlight_js_language_loader', () => ({
  javascript: jest.fn().mockReturnValue({ default: jest.fn() }),
}));

jest.mock('~/vue_shared/components/source_viewer/plugins/index', () => ({
  registerPlugins: jest.fn(),
}));

const fileType = 'text';
const content = 'function test() { return true };';
const language = 'javascript';

describe('Highlight utility', () => {
  beforeEach(() => highlight(fileType, content, language));

  it('loads the language', () => {
    expect(languageLoader.javascript).toHaveBeenCalled();
  });

  it('registers the plugins', () => {
    expect(registerPlugins).toHaveBeenCalled();
  });

  it('registers the language', () => {
    expect(hljs.registerLanguage).toHaveBeenCalledWith(
      language,
      languageLoader[language]().default,
    );
  });

  it('highlights the content', () => {
    expect(hljs.highlight).toHaveBeenCalledWith(content, { language });
  });
});
