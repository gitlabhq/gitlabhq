import CodeBlockLanguageBlocker from '~/content_editor/services/code_block_language_loader';

describe('content_editor/services/code_block_language_loader', () => {
  let languageLoader;
  let lowlight;

  beforeEach(() => {
    lowlight = {
      languages: [],
      registerLanguage: jest
        .fn()
        .mockImplementation((language) => lowlight.languages.push(language)),
      registered: jest.fn().mockImplementation((language) => lowlight.languages.includes(language)),
    };
    languageLoader = new CodeBlockLanguageBlocker(lowlight);
  });

  describe('loadLanguages', () => {
    it('loads highlight.js language packages identified by a list of languages', async () => {
      const languages = ['javascript', 'ruby'];

      await languageLoader.loadLanguages(languages);

      languages.forEach((language) => {
        expect(lowlight.registerLanguage).toHaveBeenCalledWith(language, expect.any(Function));
      });
    });

    describe('when language is already registered', () => {
      it('does not load the language again', async () => {
        const languages = ['javascript'];

        await languageLoader.loadLanguages(languages);
        await languageLoader.loadLanguages(languages);

        expect(lowlight.registerLanguage).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('loadLanguagesFromDOM', () => {
    it('loads highlight.js language packages identified by pre tags in a DOM fragment', async () => {
      const parser = new DOMParser();
      const { body } = parser.parseFromString(
        `
      <pre lang="javascript"></pre>
      <pre lang="ruby"></pre>
      `,
        'text/html',
      );

      await languageLoader.loadLanguagesFromDOM(body);

      expect(lowlight.registerLanguage).toHaveBeenCalledWith('javascript', expect.any(Function));
      expect(lowlight.registerLanguage).toHaveBeenCalledWith('ruby', expect.any(Function));
    });
  });

  describe('isLanguageLoaded', () => {
    it('returns true when a language is registered', async () => {
      const language = 'javascript';

      expect(languageLoader.isLanguageLoaded(language)).toBe(false);

      await languageLoader.loadLanguages([language]);

      expect(languageLoader.isLanguageLoaded(language)).toBe(true);
    });
  });
});
