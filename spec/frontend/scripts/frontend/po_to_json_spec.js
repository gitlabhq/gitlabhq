import { join } from 'path';
import { tmpdir } from 'os';
import { readFile, rm, mkdtemp, stat } from 'fs/promises';
import {
  convertPoToJed,
  convertPoFileForLocale,
  main,
} from '../../../../scripts/frontend/po_to_json';

describe('PoToJson', () => {
  const LOCALE = 'de';
  const LOCALE_DIR = join(__dirname, '__fixtures__/locale');
  const PO_FILE = join(LOCALE_DIR, LOCALE, 'gitlab.po');
  const CONVERTED_FILE = join(LOCALE_DIR, LOCALE, 'converted.json');
  let DE_CONVERTED = null;

  beforeAll(async () => {
    DE_CONVERTED = Object.freeze(JSON.parse(await readFile(CONVERTED_FILE, 'utf-8')));
  });

  describe('tests writing to the file system', () => {
    let resultDir = null;

    afterEach(async () => {
      if (resultDir) {
        await rm(resultDir, { recursive: true, force: true });
      }
    });

    beforeEach(async () => {
      resultDir = await mkdtemp(join(tmpdir(), 'locale-test'));
    });

    describe('#main', () => {
      it('throws without arguments', () => {
        return expect(main()).rejects.toThrow(/doesn't seem to be a folder/);
      });

      it('throws if outputDir does not exist', () => {
        return expect(
          main({
            localeRoot: LOCALE_DIR,
            outputDir: 'i-do-not-exist',
          }),
        ).rejects.toThrow(/doesn't seem to be a folder/);
      });

      it('throws if localeRoot does not exist', () => {
        return expect(
          main({
            localeRoot: 'i-do-not-exist',
            outputDir: resultDir,
          }),
        ).rejects.toThrow(/doesn't seem to be a folder/);
      });

      it('converts folder of po files to app.js files', async () => {
        expect((await stat(resultDir)).isDirectory()).toBe(true);
        await main({ localeRoot: LOCALE_DIR, outputDir: resultDir });

        const resultFile = join(resultDir, LOCALE, 'app.js');
        expect((await stat(resultFile)).isFile()).toBe(true);

        window.translations = null;
        await import(resultFile);
        expect(window.translations).toEqual(DE_CONVERTED);
      });
    });

    describe('#convertPoFileForLocale', () => {
      it('converts simple PO to app.js, which exposes translations on the window', async () => {
        await convertPoFileForLocale({ locale: 'de', localeFile: PO_FILE, resultDir });

        const resultFile = join(resultDir, 'app.js');
        expect((await stat(resultFile)).isFile()).toBe(true);

        window.translations = null;
        await import(resultFile);
        expect(window.translations).toEqual(DE_CONVERTED);
      });
    });
  });

  describe('#convertPoToJed', () => {
    it('converts simple PO to JED compatible JSON', async () => {
      const poContent = await readFile(PO_FILE, 'utf-8');

      expect(convertPoToJed(poContent, LOCALE).jed).toEqual(DE_CONVERTED);
    });

    it('returns null for empty string', () => {
      const poContent = '';

      expect(convertPoToJed(poContent, LOCALE).jed).toEqual(null);
    });

    describe('PO File headers', () => {
      it('parses headers properly', () => {
        const poContent = `
msgid ""
msgstr ""
"Project-Id-Version: gitlab-ee\\n"
"Report-Msgid-Bugs-To: \\n"
"X-Crowdin-Project: gitlab-ee\\n"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                'Project-Id-Version': 'gitlab-ee',
                'Report-Msgid-Bugs-To': '',
                'X-Crowdin-Project': 'gitlab-ee',
                domain: 'app',
                lang: LOCALE,
              },
            },
          },
        });
      });

      // JED needs that property, hopefully we could get
      // rid of this in a future iteration
      it("exposes 'Plural-Forms' as 'plural_forms' for `jed`", () => {
        const poContent = `
msgid ""
msgstr ""
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                'Plural-Forms': 'nplurals=2; plural=(n != 1);',
                plural_forms: 'nplurals=2; plural=(n != 1);',
                domain: 'app',
                lang: LOCALE,
              },
            },
          },
        });
      });

      it('removes POT-Creation-Date', () => {
        const poContent = `
msgid ""
msgstr ""
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                'Plural-Forms': 'nplurals=2; plural=(n != 1);',
                plural_forms: 'nplurals=2; plural=(n != 1);',
                domain: 'app',
                lang: LOCALE,
              },
            },
          },
        });
      });
    });

    describe('escaping', () => {
      it('escapes quotes in translation', () => {
        const poContent = `
# Escaped quotes in msgid and msgstr
msgid "Changes the title to \\"%{title_param}\\"."
msgstr "Ändert den Titel in \\"%{title_param}\\"."
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                domain: 'app',
                lang: LOCALE,
              },
              'Changes the title to "%{title_param}".': [
                'Ändert den Titel in \\"%{title_param}\\".',
              ],
            },
          },
        });
      });

      it('escapes backslashes in translation', () => {
        const poContent = `
# Escaped backslashes in msgid and msgstr
msgid "Example: ssh\\\\:\\\\/\\\\/"
msgstr "Beispiel: ssh\\\\:\\\\/\\\\/"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                domain: 'app',
                lang: LOCALE,
              },
              'Example: ssh\\:\\/\\/': ['Beispiel: ssh\\\\:\\\\/\\\\/'],
            },
          },
        });
      });

      // This is potentially faulty behavior but demands further investigation
      // See also the escapeMsgstr method
      it('escapes \\n and \\t in translation', () => {
        const poContent = `
# Escaped \\n
msgid "Outdent line"
msgstr "Désindenter la ligne\\n"

# Escaped \\t
msgid "Headers"
msgstr "Cabeçalhos\\t"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                domain: 'app',
                lang: LOCALE,
              },
              Headers: ['Cabeçalhos\\t'],
              'Outdent line': ['Désindenter la ligne\\n'],
            },
          },
        });
      });
    });
  });
});
