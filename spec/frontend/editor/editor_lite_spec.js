/* eslint-disable max-classes-per-file */
import { editor as monacoEditor, languages as monacoLanguages, Uri } from 'monaco-editor';
import waitForPromises from 'helpers/wait_for_promises';
import Editor from '~/editor/editor_lite';
import { EditorLiteExtension } from '~/editor/extensions/editor_lite_extension_base';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import { EDITOR_LITE_INSTANCE_ERROR_NO_EL, URI_PREFIX } from '~/editor/constants';

describe('Base editor', () => {
  let editorEl;
  let editor;
  const blobContent = 'Foo Bar';
  const blobPath = 'test.md';
  const blobGlobalId = 'snippet_777';
  const fakeModel = { foo: 'bar', dispose: jest.fn() };

  beforeEach(() => {
    setFixtures('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new Editor();
  });

  afterEach(() => {
    editor.dispose();
    editorEl.remove();
  });

  const createUri = (...paths) => Uri.file([URI_PREFIX, ...paths].join('/'));

  it('initializes Editor with basic properties', () => {
    expect(editor).toBeDefined();
    expect(editor.instances).toEqual([]);
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
        onDidDispose: jest.fn(),
      }));
    });

    it('throws an error if no dom element is supplied', () => {
      expect(() => {
        editor.createInstance();
      }).toThrow(EDITOR_LITE_INSTANCE_ERROR_NO_EL);

      expect(modelSpy).not.toHaveBeenCalled();
      expect(instanceSpy).not.toHaveBeenCalled();
      expect(setModel).not.toHaveBeenCalled();
    });

    it('creates model to be supplied to Monaco editor', () => {
      editor.createInstance({ el: editorEl, blobPath, blobContent, blobGlobalId: '' });

      expect(modelSpy).toHaveBeenCalledWith(blobContent, undefined, createUri(blobPath));
      expect(setModel).toHaveBeenCalledWith(fakeModel);
    });

    it('initializes the instance on a supplied DOM node', () => {
      editor.createInstance({ el: editorEl });

      expect(editor.editorEl).not.toBe(null);
      expect(instanceSpy).toHaveBeenCalledWith(editorEl, expect.anything());
    });

    it('with blobGlobalId, creates model with id in uri', () => {
      editor.createInstance({ el: editorEl, blobPath, blobContent, blobGlobalId });

      expect(modelSpy).toHaveBeenCalledWith(
        blobContent,
        undefined,
        createUri(blobGlobalId, blobPath),
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
      expect(instanceSpy).toHaveBeenCalledWith(editorEl, expect.objectContaining(instanceOptions));
    });

    it('disposes instance when the editor is disposed', () => {
      editor.createInstance({ el: editorEl, blobPath, blobContent, blobGlobalId });

      expect(dispose).not.toHaveBeenCalled();

      editor.dispose();

      expect(dispose).toHaveBeenCalled();
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
    const readOnlyIndex = '68'; // readOnly option has the internal index of 68 in the editor's options

    beforeEach(() => {
      setFixtures('<div id="editor1"></div><div id="editor2"></div>');
      editorEl1 = document.getElementById('editor1');
      editorEl2 = document.getElementById('editor2');
      inst1Args = {
        el: editorEl1,
        blobGlobalId,
      };
      inst2Args = {
        el: editorEl2,
        blobContent,
        blobPath,
        blobGlobalId,
      };

      editor = new Editor();
      instanceSpy = jest.spyOn(monacoEditor, 'create');
    });

    afterEach(() => {
      editor.dispose();
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

    it('shares global editor options among all instances', () => {
      editor = new Editor({
        readOnly: true,
      });

      inst1 = editor.createInstance(inst1Args);
      expect(inst1.getOption(readOnlyIndex)).toBe(true);

      inst2 = editor.createInstance(inst2Args);
      expect(inst2.getOption(readOnlyIndex)).toBe(true);
    });

    it('allows overriding editor options on the instance level', () => {
      editor = new Editor({
        readOnly: true,
      });
      inst1 = editor.createInstance({
        ...inst1Args,
        readOnly: false,
      });

      expect(inst1.getOption(readOnlyIndex)).toBe(false);
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
    beforeEach(() => {
      instance = editor.createInstance({ el: editorEl, blobPath, blobContent });
    });

    it('correctly proxies value from the model', () => {
      expect(instance.getValue()).toBe(blobContent);
    });

    it('is capable of changing the language of the model', () => {
      // ignore warnings and errors Monaco posts during setup
      // (due to being called from Jest/Node.js environment)
      jest.spyOn(console, 'warn').mockImplementation(() => {});
      jest.spyOn(console, 'error').mockImplementation(() => {});

      const blobRenamedPath = 'test.js';

      expect(instance.getModel().getLanguageIdentifier().language).toBe('markdown');
      instance.updateModelLanguage(blobRenamedPath);

      expect(instance.getModel().getLanguageIdentifier().language).toBe('javascript');
    });

    it('falls back to plaintext if there is no language associated with an extension', () => {
      const blobRenamedPath = 'test.myext';
      const spy = jest.spyOn(console, 'error').mockImplementation(() => {});

      instance.updateModelLanguage(blobRenamedPath);

      expect(spy).not.toHaveBeenCalled();
      expect(instance.getModel().getLanguageIdentifier().language).toBe('plaintext');
    });
  });

  describe('extensions', () => {
    let instance;
    const alphaRes = jest.fn();
    const betaRes = jest.fn();
    const fooRes = jest.fn();
    const barRes = jest.fn();
    class AlphaClass {
      constructor() {
        this.res = alphaRes;
      }
      alpha() {
        return this?.nonExistentProp || alphaRes;
      }
    }
    class BetaClass {
      beta() {
        return this?.nonExistentProp || betaRes;
      }
    }
    class WithStaticMethod {
      constructor({ instance: inst, ...options } = {}) {
        Object.assign(inst, options);
      }
      static computeBoo(a) {
        return a + 1;
      }
      boo() {
        return WithStaticMethod.computeBoo(this.base);
      }
    }
    class WithStaticMethodExtended extends EditorLiteExtension {
      static computeBoo(a) {
        return a + 1;
      }
      boo() {
        return WithStaticMethodExtended.computeBoo(this.base);
      }
    }
    const AlphaExt = new AlphaClass();
    const BetaExt = new BetaClass();
    const FooObjExt = {
      foo() {
        return fooRes;
      },
    };
    const BarObjExt = {
      bar() {
        return barRes;
      },
    };

    describe('basic functionality', () => {
      beforeEach(() => {
        instance = editor.createInstance({ el: editorEl, blobPath, blobContent });
      });

      it('does not fail if no extensions supplied', () => {
        const spy = jest.spyOn(global.console, 'error');
        instance.use();

        expect(spy).not.toHaveBeenCalled();
      });

      it("does not extend instance with extension's constructor", () => {
        expect(instance.constructor).toBeDefined();
        const { constructor } = instance;

        expect(AlphaExt.constructor).toBeDefined();
        expect(AlphaExt.constructor).not.toEqual(constructor);

        instance.use(AlphaExt);
        expect(instance.constructor).toBe(constructor);
      });

      it.each`
        type                                        | extensions                | methods              | expectations
        ${'ES6 classes'}                            | ${AlphaExt}               | ${['alpha']}         | ${[alphaRes]}
        ${'multiple ES6 classes'}                   | ${[AlphaExt, BetaExt]}    | ${['alpha', 'beta']} | ${[alphaRes, betaRes]}
        ${'simple objects'}                         | ${FooObjExt}              | ${['foo']}           | ${[fooRes]}
        ${'multiple simple objects'}                | ${[FooObjExt, BarObjExt]} | ${['foo', 'bar']}    | ${[fooRes, barRes]}
        ${'combination of ES6 classes and objects'} | ${[AlphaExt, BarObjExt]}  | ${['alpha', 'bar']}  | ${[alphaRes, barRes]}
      `('is extensible with $type', ({ extensions, methods, expectations } = {}) => {
        methods.forEach((method) => {
          expect(instance[method]).toBeUndefined();
        });

        instance.use(extensions);

        methods.forEach((method) => {
          expect(instance[method]).toBeDefined();
        });

        expectations.forEach((expectation, i) => {
          expect(instance[methods[i]].call()).toEqual(expectation);
        });
      });

      it('does not extend instance with private data of an extension', () => {
        const ext = new WithStaticMethod({ instance });
        ext.staticMethod = () => {
          return 'foo';
        };
        ext.staticProp = 'bar';

        expect(instance.boo).toBeUndefined();
        expect(instance.staticMethod).toBeUndefined();
        expect(instance.staticProp).toBeUndefined();

        instance.use(ext);

        expect(instance.boo).toBeDefined();
        expect(instance.staticMethod).toBeUndefined();
        expect(instance.staticProp).toBeUndefined();
      });

      it.each([WithStaticMethod, WithStaticMethodExtended])(
        'properly resolves data for an extension with private data',
        (ExtClass) => {
          const base = 1;
          expect(instance.base).toBeUndefined();
          expect(instance.boo).toBeUndefined();

          const ext = new ExtClass({ instance, base });

          instance.use(ext);
          expect(instance.base).toBe(1);
          expect(instance.boo()).toBe(2);
        },
      );

      it('uses the last definition of a method in case of an overlap', () => {
        const FooObjExt2 = { foo: 'foo2' };
        instance.use([FooObjExt, BarObjExt, FooObjExt2]);
        expect(instance).toMatchObject({
          foo: 'foo2',
          ...BarObjExt,
        });
      });

      it('correctly resolves references withing extensions', () => {
        const FunctionExt = {
          inst() {
            return this;
          },
          mod() {
            return this.getModel();
          },
        };
        instance.use(FunctionExt);
        expect(instance.inst()).toEqual(editor.instances[0]);
      });
    });

    describe('extensions as an instance parameter', () => {
      let editorExtensionSpy;
      const instanceConstructor = (extensions = []) => {
        return editor.createInstance({
          el: editorEl,
          blobPath,
          blobContent,
          blobGlobalId,
          extensions,
        });
      };

      beforeEach(() => {
        editorExtensionSpy = jest.spyOn(Editor, 'pushToImportsArray').mockImplementation((arr) => {
          arr.push(
            Promise.resolve({
              default: {},
            }),
          );
        });
      });

      it.each([undefined, [], [''], ''])(
        'does not fail and makes no fetch if extensions is %s',
        () => {
          instance = instanceConstructor(null);
          expect(editorExtensionSpy).not.toHaveBeenCalled();
        },
      );

      it.each`
        type                  | value             | callsCount
        ${'simple string'}    | ${'foo'}          | ${1}
        ${'combined string'}  | ${'foo, bar'}     | ${2}
        ${'array of strings'} | ${['foo', 'bar']} | ${2}
      `('accepts $type as an extension parameter', ({ value, callsCount }) => {
        instance = instanceConstructor(value);
        expect(editorExtensionSpy).toHaveBeenCalled();
        expect(editorExtensionSpy.mock.calls).toHaveLength(callsCount);
      });

      it.each`
        desc                                     | path                      | expectation
        ${'~/editor'}                            | ${'foo'}                  | ${'~/editor/foo'}
        ${'~/CUSTOM_PATH with leading slash'}    | ${'/my_custom_path/bar'}  | ${'~/my_custom_path/bar'}
        ${'~/CUSTOM_PATH without leading slash'} | ${'my_custom_path/delta'} | ${'~/my_custom_path/delta'}
      `('fetches extensions from $desc path', ({ path, expectation }) => {
        instance = instanceConstructor(path);
        expect(editorExtensionSpy).toHaveBeenCalledWith(expect.any(Array), expectation);
      });

      it('emits editor-ready event after all extensions were applied', async () => {
        const calls = [];
        const eventSpy = jest.fn().mockImplementation(() => {
          calls.push('event');
        });
        const useSpy = jest.spyOn(editor, 'use').mockImplementation(() => {
          calls.push('use');
        });
        editorEl.addEventListener('editor-ready', eventSpy);
        instance = instanceConstructor('foo, bar');
        await waitForPromises();
        expect(useSpy.mock.calls).toHaveLength(2);
        expect(calls).toEqual(['use', 'use', 'event']);
      });
    });

    describe('multiple instances', () => {
      let inst1;
      let inst2;
      let editorEl1;
      let editorEl2;

      beforeEach(() => {
        setFixtures('<div id="editor1"></div><div id="editor2"></div>');
        editorEl1 = document.getElementById('editor1');
        editorEl2 = document.getElementById('editor2');
        inst1 = editor.createInstance({ el: editorEl1, blobPath: `foo-${blobPath}` });
        inst2 = editor.createInstance({ el: editorEl2, blobPath: `bar-${blobPath}` });
      });

      afterEach(() => {
        editor.dispose();
        editorEl1.remove();
        editorEl2.remove();
      });

      it('extends all instances if no specific instance is passed', () => {
        editor.use(AlphaExt);
        expect(inst1.alpha()).toEqual(alphaRes);
        expect(inst2.alpha()).toEqual(alphaRes);
      });

      it('extends specific instance if it has been passed', () => {
        editor.use(AlphaExt, inst2);
        expect(inst1.alpha).toBeUndefined();
        expect(inst2.alpha()).toEqual(alphaRes);
      });
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

      editor = new Editor();

      expect(themeDefineSpy).toHaveBeenCalledWith(DEFAULT_THEME, expectedTheme.data);
      expect(themeSetSpy).toHaveBeenCalledWith(DEFAULT_THEME);
    });

    it('sets correct theme if it is set in users preferences', () => {
      const expectedTheme = themes.find((t) => t.name !== DEFAULT_THEME);

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
