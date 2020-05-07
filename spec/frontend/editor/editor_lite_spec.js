import { editor as monacoEditor, languages as monacoLanguages, Uri } from 'monaco-editor';
import Editor from '~/editor/editor_lite';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';

describe('Base editor', () => {
  let editorEl;
  let editor;
  const blobContent = 'Foo Bar';
  const blobPath = 'test.md';
  const uri = new Uri('gitlab', false, blobPath);
  const fakeModel = { foo: 'bar' };

  beforeEach(() => {
    setFixtures('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new Editor();
  });

  afterEach(() => {
    editor.dispose();
    editorEl.remove();
  });

  it('initializes Editor with basic properties', () => {
    expect(editor).toBeDefined();
    expect(editor.editorEl).toBe(null);
    expect(editor.blobContent).toEqual('');
    expect(editor.blobPath).toEqual('');
  });

  it('removes `editor-loading` data attribute from the target DOM element', () => {
    editor.createInstance({ el: editorEl });

    expect(editorEl.dataset.editorLoading).toBeUndefined();
  });

  describe('instance of the Editor', () => {
    let modelSpy;
    let instanceSpy;
    let setModel;
    let dispose;

    beforeEach(() => {
      setModel = jest.fn();
      dispose = jest.fn();
      modelSpy = jest.spyOn(monacoEditor, 'createModel').mockImplementation(() => fakeModel);
      instanceSpy = jest.spyOn(monacoEditor, 'create').mockImplementation(() => ({
        setModel,
        dispose,
      }));
    });

    it('does nothing if no dom element is supplied', () => {
      editor.createInstance();

      expect(editor.editorEl).toBe(null);
      expect(editor.blobContent).toEqual('');
      expect(editor.blobPath).toEqual('');

      expect(modelSpy).not.toHaveBeenCalled();
      expect(instanceSpy).not.toHaveBeenCalled();
      expect(setModel).not.toHaveBeenCalled();
    });

    it('creates model to be supplied to Monaco editor', () => {
      editor.createInstance({ el: editorEl, blobPath, blobContent });

      expect(modelSpy).toHaveBeenCalledWith(blobContent, undefined, uri);
      expect(setModel).toHaveBeenCalledWith(fakeModel);
    });

    it('initializes the instance on a supplied DOM node', () => {
      editor.createInstance({ el: editorEl });

      expect(editor.editorEl).not.toBe(null);
      expect(instanceSpy).toHaveBeenCalledWith(editorEl, expect.anything());
    });
  });

  describe('implementation', () => {
    beforeEach(() => {
      editor.createInstance({ el: editorEl, blobPath, blobContent });
    });

    afterEach(() => {
      editor.model.dispose();
    });

    it('correctly proxies value from the model', () => {
      expect(editor.getValue()).toEqual(blobContent);
    });

    it('is capable of changing the language of the model', () => {
      // ignore warnings and errors Monaco posts during setup
      // (due to being called from Jest/Node.js environment)
      jest.spyOn(console, 'warn').mockImplementation(() => {});
      jest.spyOn(console, 'error').mockImplementation(() => {});

      const blobRenamedPath = 'test.js';

      expect(editor.model.getLanguageIdentifier().language).toEqual('markdown');
      editor.updateModelLanguage(blobRenamedPath);

      expect(editor.model.getLanguageIdentifier().language).toEqual('javascript');
    });

    it('falls back to plaintext if there is no language associated with an extension', () => {
      const blobRenamedPath = 'test.myext';
      const spy = jest.spyOn(console, 'error').mockImplementation(() => {});

      editor.updateModelLanguage(blobRenamedPath);

      expect(spy).not.toHaveBeenCalled();
      expect(editor.model.getLanguageIdentifier().language).toEqual('plaintext');
    });
  });

  describe('languages', () => {
    it('registers custom languages defined with Monaco', () => {
      expect(monacoLanguages.getLanguages()).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            id: 'vue',
          }),
        ]),
      );
    });
  });

  describe('syntax highlighting theme', () => {
    let themeDefineSpy;
    let themeSetSpy;
    let defaultScheme;

    beforeEach(() => {
      themeDefineSpy = jest.spyOn(monacoEditor, 'defineTheme').mockImplementation(() => {});
      themeSetSpy = jest.spyOn(monacoEditor, 'setTheme').mockImplementation(() => {});
      defaultScheme = window.gon.user_color_scheme;
    });

    afterEach(() => {
      window.gon.user_color_scheme = defaultScheme;
    });

    it('sets default syntax highlighting theme', () => {
      const expectedTheme = themes.find(t => t.name === DEFAULT_THEME);

      editor = new Editor();

      expect(themeDefineSpy).toHaveBeenCalledWith(DEFAULT_THEME, expectedTheme.data);
      expect(themeSetSpy).toHaveBeenCalledWith(DEFAULT_THEME);
    });

    it('sets correct theme if it is set in users preferences', () => {
      const expectedTheme = themes.find(t => t.name !== DEFAULT_THEME);

      expect(expectedTheme.name).not.toBe(DEFAULT_THEME);

      window.gon.user_color_scheme = expectedTheme.name;
      editor = new Editor();

      expect(themeDefineSpy).toHaveBeenCalledWith(expectedTheme.name, expectedTheme.data);
      expect(themeSetSpy).toHaveBeenCalledWith(expectedTheme.name);
    });

    it('falls back to default theme if a selected one is not supported yet', () => {
      const name = 'non-existent-theme';
      const nonExistentTheme = { name };

      window.gon.user_color_scheme = nonExistentTheme.name;
      editor = new Editor();

      expect(themeDefineSpy).not.toHaveBeenCalled();
      expect(themeSetSpy).toHaveBeenCalledWith(DEFAULT_THEME);
    });
  });
});
