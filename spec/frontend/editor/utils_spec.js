import { editor as monacoEditor } from 'monaco-editor';
import EditorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker';
import JsonWorker from 'monaco-editor/esm/vs/language/json/json.worker?worker';
import YamlWorker from '~/editor/monaco_yaml_worker?worker';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import * as utils from '~/editor/utils';
import languages from '~/ide/lib/languages';
import { registerLanguages } from '~/ide/utils';
import { DEFAULT_THEME } from '~/ide/lib/themes';

jest.mock('monaco-editor/esm/vs/editor/editor.worker?worker', () => jest.fn());
jest.mock('monaco-editor/esm/vs/language/json/json.worker?worker', () => jest.fn());
jest.mock('~/editor/monaco_yaml_worker?worker', () => jest.fn());

describe('Source Editor utils', () => {
  let el;

  const stubUserColorScheme = (value) => {
    if (window.gon == null) {
      window.gon = {};
    }
    window.gon.user_color_scheme = value;
  };

  describe('clearDomElement', () => {
    beforeEach(() => {
      setHTMLFixture('<div id="foo"><div id="bar">Foo</div></div>');
      el = document.getElementById('foo');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('removes all child nodes from an element', () => {
      expect(el.children).toHaveLength(1);
      utils.clearDomElement(el);
      expect(el.children).toHaveLength(0);
    });
  });

  describe('setupEditorTheme', () => {
    beforeEach(() => {
      jest.spyOn(monacoEditor, 'defineTheme').mockImplementation();
      jest.spyOn(monacoEditor, 'setTheme').mockImplementation();
    });

    it.each`
      themeName            | expectedThemeName
      ${'solarized-light'} | ${'solarized-light'}
      ${DEFAULT_THEME}     | ${DEFAULT_THEME}
      ${'non-existent'}    | ${DEFAULT_THEME}
    `(
      'sets the $expectedThemeName theme when $themeName is set in the user preference',
      ({ themeName, expectedThemeName }) => {
        stubUserColorScheme(themeName);
        utils.setupEditorTheme();

        expect(monacoEditor.setTheme).toHaveBeenCalledWith(expectedThemeName);
      },
    );
  });

  describe('getBlobLanguage', () => {
    beforeEach(() => {
      registerLanguages(...languages);
    });

    it.each`
      path                    | expectedLanguage
      ${'foo.js'}             | ${'javascript'}
      ${'foo.js.rb'}          | ${'ruby'}
      ${'foo.bar'}            | ${'plaintext'}
      ${undefined}            | ${'plaintext'}
      ${'foo/bar/foo.js'}     | ${'javascript'}
      ${'CODEOWNERS'}         | ${'codeowners'}
      ${'.gitlab/CODEOWNERS'} | ${'codeowners'}
    `(`returns '$expectedLanguage' for '$path' path`, ({ path, expectedLanguage }) => {
      const language = utils.getBlobLanguage(path);

      expect(language).toEqual(expectedLanguage);
    });
  });

  describe('setupCodeSnipet', () => {
    beforeEach(() => {
      jest.spyOn(monacoEditor, 'colorizeElement').mockImplementation();
      jest.spyOn(monacoEditor, 'setTheme').mockImplementation();
      setHTMLFixture('<pre id="foo"></pre>');
      el = document.getElementById('foo');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('colorizes the element and applies the preference theme', () => {
      expect(monacoEditor.colorizeElement).not.toHaveBeenCalled();
      expect(monacoEditor.setTheme).not.toHaveBeenCalled();

      utils.setupCodeSnippet(el);

      expect(monacoEditor.colorizeElement).toHaveBeenCalledWith(el);
      expect(monacoEditor.setTheme).toHaveBeenCalled();
    });
  });

  describe('enableMonacoWorkers', () => {
    it('does not set up the worker for non-Vite environments', () => {
      utils.enableMonacoWorkers();
      expect(window.MonacoEnvironment).toBeUndefined();
    });

    describe('when IS_VITE is true', () => {
      beforeEach(() => {
        window.IS_VITE = true;
        utils.enableMonacoWorkers();
      });

      afterEach(() => {
        delete window.IS_VITE;
        delete window.MonacoEnvironment;
      });

      it('sets up the worker', () => {
        expect(window.MonacoEnvironment).toBeDefined();
      });

      it.each`
        label                    | Worker
        ${'json'}                | ${JsonWorker}
        ${'yaml'}                | ${YamlWorker}
        ${'editorWorkerService'} | ${EditorWorker}
      `('returns the $label worker', async ({ label, Worker }) => {
        const worker = await window.MonacoEnvironment.getWorker('workerMain.js', label);

        expect(worker).toBeInstanceOf(Worker);
      });

      it('throws for an unknown label', async () => {
        await expect(window.MonacoEnvironment.getWorker('workerMain.js', 'foo')).rejects.toThrow(
          'Unknown Monaco worker label: "foo"',
        );
      });
    });
  });
});
