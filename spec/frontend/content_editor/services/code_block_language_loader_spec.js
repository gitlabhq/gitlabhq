import codeBlockLanguageBlocker from '~/content_editor/services/code_block_language_loader';
import waitForPromises from 'helpers/wait_for_promises';
import { backtickInputRegex } from '~/content_editor/extensions/code_block_highlight';

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
    languageLoader = codeBlockLanguageBlocker;
    languageLoader.lowlight = lowlight;
  });

  describe('findLanguageBySyntax', () => {
    it.each`
      syntax          | language
      ${'javascript'} | ${{ syntax: 'javascript', label: 'Javascript' }}
      ${'js'}         | ${{ syntax: 'javascript', label: 'Javascript' }}
      ${'jsx'}        | ${{ syntax: 'javascript', label: 'Javascript' }}
    `('returns a language by syntax and its variants', ({ syntax, language }) => {
      expect(languageLoader.findLanguageBySyntax(syntax)).toMatchObject(language);
    });

    it('returns Custom (syntax) if the language does not exist', () => {
      expect(languageLoader.findLanguageBySyntax('foobar')).toMatchObject({
        syntax: 'foobar',
        label: 'Custom (foobar)',
      });
    });

    it('returns plaintext if no syntax is passed', () => {
      expect(languageLoader.findLanguageBySyntax('')).toMatchObject({
        syntax: 'plaintext',
        label: 'Plain text',
      });
    });
  });

  describe('filterLanguages', () => {
    it('filters languages by the given search term', () => {
      expect(languageLoader.filterLanguages('ts')).toEqual([
        { label: 'Device Tree', syntax: 'dts' },
        { label: 'Kotlin', syntax: 'kotlin', variants: 'kt, kts' },
        { label: 'TypeScript', syntax: 'typescript', variants: 'ts, tsx' },
      ]);
    });
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

  describe('loadLanguageFromInputRule', () => {
    it('loads highlight.js language packages identified from the input rule', async () => {
      const match = new RegExp(backtickInputRegex).exec('```js ');
      const attrs = languageLoader.loadLanguageFromInputRule(match);

      await waitForPromises();

      expect(attrs).toEqual({ language: 'javascript' });
      expect(lowlight.registerLanguage).toHaveBeenCalledWith('javascript', expect.any(Function));
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
