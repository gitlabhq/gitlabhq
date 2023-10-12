import { editor as monacoEditor, languages as monacoLanguages } from 'monaco-editor';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  SOURCE_EDITOR_INSTANCE_ERROR_NO_EL,
  URI_PREFIX,
  EDITOR_READY_EVENT,
} from '~/editor/constants';
import SourceEditor from '~/editor/source_editor';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import { joinPaths } from '~/lib/utils/url_utility';

describe('Base editor', () => {
  let editorEl;
  let editor;
  let defaultArguments;
  const blobOriginalContent = 'Foo Foo';
  const blobContent = 'Foo Bar';
  const blobPath = 'test.md';
  const blobGlobalId = 'snippet_777';

  beforeEach(() => {
    setHTMLFixture('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    defaultArguments = { el: editorEl, blobPath, blobContent, blobGlobalId };
    editor = new SourceEditor();
  });

  afterEach(() => {
    editor.dispose();
    editorEl.remove();
    monacoEditor.getModels().forEach((model) => {
      model.dispose();
    });

    resetHTMLFixture();
  });

  const uriFilePath = joinPaths('/', URI_PREFIX, blobGlobalId, blobPath);

  it('initializes Editor with basic properties', () => {
    expect(editor).toBeDefined();
    expect(editor.instances).toEqual([]);
  });

  it('removes `editor-loading` data attribute from the target DOM element', () => {
    editor.createInstance({ el: editorEl });

    expect(editorEl.dataset.editorLoading).toBeUndefined();
  });

  describe('instance of the Source Editor', () => {
    let modelSpy;
    let instanceSpy;

    beforeEach(() => {
      modelSpy = jest.spyOn(monacoEditor, 'createModel');
    });

    describe('instance of the Code Editor', () => {
      beforeEach(() => {
        instanceSpy = jest.spyOn(monacoEditor, 'create');
      });

      it('throws an error if no dom element is supplied', () => {
        const create = () => {
          editor.createInstance();
        };
        expect(create).toThrow(SOURCE_EDITOR_INSTANCE_ERROR_NO_EL);

        expect(modelSpy).not.toHaveBeenCalled();
        expect(instanceSpy).not.toHaveBeenCalled();
      });

      it('creates model and attaches it to the instance', () => {
        jest.spyOn(monacoEditor, 'createModel');
        const instance = editor.createInstance(defaultArguments);

        expect(monacoEditor.createModel).toHaveBeenCalledWith(
          blobContent,
          'markdown',
          expect.objectContaining({
            path: uriFilePath,
          }),
        );
        expect(instance.getModel().getValue()).toEqual(defaultArguments.blobContent);
      });

      it('does not create a model automatically if model is passed as `null`', () => {
        const instance = editor.createInstance({ ...defaultArguments, model: null });
        expect(instance.getModel()).toBeNull();
      });

      it('initializes the instance on a supplied DOM node', () => {
        editor.createInstance({ el: editorEl });

        expect(editor.editorEl).not.toBeNull();
        expect(instanceSpy).toHaveBeenCalledWith(editorEl, expect.anything());
      });

      it('with blobGlobalId, creates model with the id in uri', () => {
        editor.createInstance(defaultArguments);

        expect(modelSpy).toHaveBeenCalledWith(
          blobContent,
          'markdown',
          expect.objectContaining({
            path: uriFilePath,
          }),
        );
      });

      it('initializes instance with passed properties', () => {
        const instanceOptions = {
          foo: 'bar',
        };
        editor.createInstance({
          el: editorEl,
          ...instanceOptions,
        });
        expect(instanceSpy).toHaveBeenCalledWith(
          editorEl,
          expect.objectContaining(instanceOptions),
        );
      });

      it('disposes instance when the global editor is disposed', () => {
        const instance = editor.createInstance(defaultArguments);
        instance.dispose = jest.fn();

        expect(instance.dispose).not.toHaveBeenCalled();

        editor.dispose();

        expect(instance.dispose).toHaveBeenCalled();
      });

      it("removes the disposed instance from the global editor's storage and disposes the associated model", () => {
        const instance = editor.createInstance(defaultArguments);

        expect(editor.instances).toHaveLength(1);
        expect(instance.getModel()).not.toBeNull();

        instance.dispose();

        expect(editor.instances).toHaveLength(0);
        expect(instance.getModel()).toBeNull();
      });

      it('resets the layout in createInstance', () => {
        const layoutSpy = jest.fn();
        jest.spyOn(monacoEditor, 'create').mockReturnValue({
          layout: layoutSpy,
          setModel: jest.fn(),
          onDidDispose: jest.fn(),
          dispose: jest.fn(),
        });
        editor.createInstance(defaultArguments);

        expect(layoutSpy).toHaveBeenCalled();
      });

      it.each`
        params                                          | expectedLanguage
        ${{}}                                           | ${'markdown'}
        ${{ blobPath: undefined }}                      | ${'plaintext'}
        ${{ blobPath: undefined, language: 'ruby' }}    | ${'ruby'}
        ${{ language: 'go' }}                           | ${'go'}
        ${{ blobPath: undefined, language: undefined }} | ${'plaintext'}
      `(
        'correctly sets $expectedLanguage on the model when $params are passed',
        ({ params, expectedLanguage }) => {
          jest.spyOn(monacoEditor, 'createModel');
          editor.createInstance({
            ...defaultArguments,
            ...params,
          });
          expect(monacoEditor.createModel).toHaveBeenCalledWith(
            expect.anything(),
            expectedLanguage,
            expect.anything(),
          );
        },
      );
    });

    describe('instance of the Diff Editor', () => {
      beforeEach(() => {
        instanceSpy = jest.spyOn(monacoEditor, 'createDiffEditor');
      });

      it('Diff Editor goes through the normal path of Code Editor just with the flag ON', () => {
        const spy = jest.spyOn(editor, 'createInstance').mockImplementation(() => {});
        editor.createDiffInstance();
        expect(spy).toHaveBeenCalledWith(
          expect.objectContaining({
            isDiff: true,
          }),
        );
      });

      it('initializes the instance on a supplied DOM node', () => {
        const wrongInstanceSpy = jest.spyOn(monacoEditor, 'create').mockImplementation(() => ({}));
        editor.createDiffInstance({ ...defaultArguments, blobOriginalContent });

        expect(editor.editorEl).not.toBe(null);
        expect(wrongInstanceSpy).not.toHaveBeenCalled();
        expect(instanceSpy).toHaveBeenCalledWith(editorEl, expect.anything());
      });

      it('creates correct model for the Diff Editor', () => {
        const instance = editor.createDiffInstance({ ...defaultArguments, blobOriginalContent });
        const getDiffModelValue = (model) => instance.getModel()[model].getValue();

        expect(modelSpy).toHaveBeenCalledTimes(2);
        expect(modelSpy.mock.calls[0]).toEqual([
          blobContent,
          'markdown',
          expect.objectContaining({
            path: uriFilePath,
          }),
        ]);
        expect(modelSpy.mock.calls[1]).toEqual([blobOriginalContent, 'markdown']);
        expect(getDiffModelValue('original')).toBe(blobOriginalContent);
        expect(getDiffModelValue('modified')).toBe(blobContent);
      });

      it('correctly disposes the diff editor model', () => {
        const instance = editor.createDiffInstance({ ...defaultArguments, blobOriginalContent });

        expect(editor.instances).toHaveLength(1);
        expect(instance.getOriginalEditor().getModel()).not.toBeNull();
        expect(instance.getModifiedEditor().getModel()).not.toBeNull();

        instance.dispose();

        expect(editor.instances).toHaveLength(0);
        expect(instance.getOriginalEditor().getModel()).toBeNull();
        expect(instance.getModifiedEditor().getModel()).toBeNull();
      });
    });
  });

  describe('multiple instances', () => {
    let instanceSpy;
    let inst1Args;
    let inst2Args;
    let editorEl1;
    let editorEl2;
    let inst1;
    let inst2;

    beforeEach(() => {
      setHTMLFixture('<div id="editor1"></div><div id="editor2"></div>');
      editorEl1 = document.getElementById('editor1');
      editorEl2 = document.getElementById('editor2');
      inst1Args = {
        el: editorEl1,
      };
      inst2Args = {
        el: editorEl2,
        blobContent,
        blobPath,
      };

      editor = new SourceEditor();
      instanceSpy = jest.spyOn(monacoEditor, 'create');
    });

    afterEach(() => {
      editor.dispose();
      resetHTMLFixture();
    });

    it('can initialize several instances of the same editor', () => {
      editor.createInstance(inst1Args);
      expect(editor.instances).toHaveLength(1);

      editor.createInstance(inst2Args);

      expect(instanceSpy).toHaveBeenCalledTimes(2);
      expect(editor.instances).toHaveLength(2);
    });

    it('sets independent models on independent instances', () => {
      inst1 = editor.createInstance(inst1Args);
      inst2 = editor.createInstance(inst2Args);

      const model1 = inst1.getModel();
      const model2 = inst2.getModel();

      expect(model1).toBeDefined();
      expect(model2).toBeDefined();
      expect(model1).not.toEqual(model2);
    });

    it('does not create a new model if a model for the path & globalId combo already exists', () => {
      const modelSpy = jest.spyOn(monacoEditor, 'createModel');
      inst1 = editor.createInstance({ ...inst2Args, blobGlobalId });
      inst2 = editor.createInstance({ ...inst2Args, el: editorEl1, blobGlobalId });

      const model1 = inst1.getModel();
      const model2 = inst2.getModel();

      expect(modelSpy).toHaveBeenCalledTimes(1);
      expect(model1).toBe(model2);
    });

    it('shares global editor options among all instances', () => {
      editor = new SourceEditor({
        readOnly: true,
      });

      inst1 = editor.createInstance(inst1Args);
      expect(inst1.getRawOptions().readOnly).toBe(true);

      inst2 = editor.createInstance(inst2Args);
      expect(inst2.getRawOptions().readOnly).toBe(true);
    });

    it('allows overriding editor options on the instance level', () => {
      editor = new SourceEditor({
        readOnly: true,
      });
      inst1 = editor.createInstance({
        ...inst1Args,
        readOnly: false,
      });

      expect(inst1.getRawOptions().readOnly).toBe(false);
    });

    it('disposes instances and relevant models independently from each other', () => {
      inst1 = editor.createInstance(inst1Args);
      inst2 = editor.createInstance(inst2Args);

      expect(inst1.getModel()).not.toBe(null);
      expect(inst2.getModel()).not.toBe(null);
      expect(editor.instances).toHaveLength(2);
      expect(monacoEditor.getModels()).toHaveLength(2);

      inst1.dispose();

      expect(inst1.getModel()).toBe(null);
      expect(inst2.getModel()).not.toBe(null);
      expect(editor.instances).toHaveLength(1);
      expect(monacoEditor.getModels()).toHaveLength(1);
    });
  });

  describe('implementation', () => {
    let instance;

    it('correctly proxies value from the model', () => {
      instance = editor.createInstance({ el: editorEl, blobPath, blobContent });
      expect(instance.getValue()).toBe(blobContent);
    });

    it('emits the EDITOR_READY_EVENT event passing the instance after setting it up', () => {
      jest.spyOn(monacoEditor, 'create').mockImplementation(() => {
        return {
          setModel: jest.fn(),
          onDidDispose: jest.fn(),
          layout: jest.fn(),
          dispose: jest.fn(),
        };
      });
      let passedInstance;
      const eventSpy = jest.fn().mockImplementation((ev) => {
        passedInstance = ev.detail.instance;
      });
      editorEl.addEventListener(EDITOR_READY_EVENT, eventSpy);
      expect(eventSpy).not.toHaveBeenCalled();
      instance = editor.createInstance({ el: editorEl });
      expect(eventSpy).toHaveBeenCalled();
      expect(passedInstance).toBe(instance);
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
      const expectedTheme = themes.find((t) => t.name === DEFAULT_THEME);

      editor = new SourceEditor();

      expect(themeDefineSpy).toHaveBeenCalledWith(DEFAULT_THEME, expectedTheme.data);
      expect(themeSetSpy).toHaveBeenCalledWith(DEFAULT_THEME);
    });

    it('sets correct theme if it is set in users preferences', () => {
      const expectedTheme = themes.find((t) => t.name !== DEFAULT_THEME);

      expect(expectedTheme.name).not.toBe(DEFAULT_THEME);

      window.gon.user_color_scheme = expectedTheme.name;
      editor = new SourceEditor();

      expect(themeDefineSpy).toHaveBeenCalledWith(expectedTheme.name, expectedTheme.data);
      expect(themeSetSpy).toHaveBeenCalledWith(expectedTheme.name);
    });

    it('falls back to default theme if a selected one is not supported yet', () => {
      const name = 'non-existent-theme';
      const nonExistentTheme = { name };

      window.gon.user_color_scheme = nonExistentTheme.name;
      editor = new SourceEditor();

      expect(themeDefineSpy).not.toHaveBeenCalled();
      expect(themeSetSpy).toHaveBeenCalledWith(DEFAULT_THEME);
    });
  });
});
