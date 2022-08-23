import {
  editor as monacoEditor,
  languages as monacoLanguages,
  Range,
  Selection,
} from 'monaco-editor';
import { EDITOR_TYPE_DIFF } from '~/editor/constants';
import Editor from '~/ide/lib/editor';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';

describe('Multi-file editor library', () => {
  let instance;
  let el;
  let holder;
  let store;

  const setNodeOffsetWidth = (val) => {
    Object.defineProperty(instance.instance.getDomNode(), 'offsetWidth', {
      get() {
        return val;
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    el = document.createElement('div');
    holder = document.createElement('div');
    el.appendChild(holder);

    document.body.appendChild(el);

    instance = Editor.create(store);
  });

  afterEach(() => {
    instance.modelManager.dispose();
    instance.dispose();
    Editor.editorInstance = null;

    el.remove();
  });

  it('creates instance of editor', () => {
    expect(Editor.editorInstance).not.toBeNull();
  });

  it('creates instance returns cached instance', () => {
    expect(Editor.create(store)).toEqual(instance);
  });

  describe('createInstance', () => {
    it('creates editor instance', () => {
      jest.spyOn(monacoEditor, 'create');

      instance.createInstance(holder);

      expect(monacoEditor.create).toHaveBeenCalled();
    });

    it('creates dirty diff controller', () => {
      instance.createInstance(holder);

      expect(instance.dirtyDiffController).not.toBeNull();
    });

    it('creates model manager', () => {
      instance.createInstance(holder);

      expect(instance.modelManager).not.toBeNull();
    });
  });

  describe('createDiffInstance', () => {
    it('creates editor instance', () => {
      jest.spyOn(monacoEditor, 'createDiffEditor');

      instance.createDiffInstance(holder);

      expect(monacoEditor.createDiffEditor).toHaveBeenCalledWith(holder, {
        ...defaultEditorOptions,
        ignoreTrimWhitespace: false,
        quickSuggestions: false,
        occurrencesHighlight: false,
        renderSideBySide: false,
        readOnly: false,
        renderLineHighlight: 'none',
        hideCursorInOverviewRuler: true,
      });
    });
  });

  describe('createModel', () => {
    it('calls model manager addModel', () => {
      jest.spyOn(instance.modelManager, 'addModel').mockImplementation(() => {});

      instance.createModel('FILE');

      expect(instance.modelManager.addModel).toHaveBeenCalledWith('FILE', null);
    });
  });

  describe('attachModel', () => {
    let model;

    beforeEach(() => {
      instance.createInstance(document.createElement('div'));

      model = instance.createModel(file());
    });

    it('sets the current model on the instance', () => {
      instance.attachModel(model);

      expect(instance.currentModel).toBe(model);
    });

    it('attaches the model to the current instance', () => {
      jest.spyOn(instance.instance, 'setModel').mockImplementation(() => {});

      instance.attachModel(model);

      expect(instance.instance.setModel).toHaveBeenCalledWith(model.getModel());
    });

    it('sets original & modified when diff editor', () => {
      jest.spyOn(instance.instance, 'getEditorType').mockReturnValue(EDITOR_TYPE_DIFF);
      jest.spyOn(instance.instance, 'setModel').mockImplementation(() => {});

      instance.attachModel(model);

      expect(instance.instance.setModel).toHaveBeenCalledWith({
        original: model.getOriginalModel(),
        modified: model.getModel(),
      });
    });

    it('attaches the model to the dirty diff controller', () => {
      jest.spyOn(instance.dirtyDiffController, 'attachModel').mockImplementation(() => {});

      instance.attachModel(model);

      expect(instance.dirtyDiffController.attachModel).toHaveBeenCalledWith(model);
    });

    it('re-decorates with the dirty diff controller', () => {
      jest.spyOn(instance.dirtyDiffController, 'reDecorate').mockImplementation(() => {});

      instance.attachModel(model);

      expect(instance.dirtyDiffController.reDecorate).toHaveBeenCalledWith(model);
    });
  });

  describe('attachMergeRequestModel', () => {
    let model;

    beforeEach(() => {
      instance.createDiffInstance(document.createElement('div'));

      const f = file();
      f.mrChanges = { diff: 'ABC' };
      f.baseRaw = 'testing';

      model = instance.createModel(f);
    });

    it('sets original & modified', () => {
      jest.spyOn(instance.instance, 'setModel').mockImplementation(() => {});

      instance.attachMergeRequestModel(model);

      expect(instance.instance.setModel).toHaveBeenCalledWith({
        original: model.getBaseModel(),
        modified: model.getModel(),
      });
    });
  });

  describe('clearEditor', () => {
    it('resets the editor model', () => {
      instance.createInstance(document.createElement('div'));

      jest.spyOn(instance.instance, 'setModel').mockImplementation(() => {});

      instance.clearEditor();

      expect(instance.instance.setModel).toHaveBeenCalledWith(null);
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

  describe('replaceSelectedText', () => {
    let model;
    let editor;

    beforeEach(() => {
      instance.createInstance(holder);

      model = instance.createModel({
        ...file(),
        key: 'index.md',
        path: 'index.md',
      });

      instance.attachModel(model);

      editor = instance.instance;
      editor.getModel().setValue('foo bar baz');
      editor.setSelection(new Range(1, 5, 1, 8));

      instance.replaceSelectedText('hello');
    });

    it('replaces the text selected in editor with the one provided', () => {
      expect(editor.getModel().getValue()).toBe('foo hello baz');
    });

    it('sets cursor to end of the replaced string', () => {
      const selection = editor.getSelection();
      expect(selection).toEqual(new Selection(1, 10, 1, 10));
    });
  });

  describe('dispose', () => {
    it('calls disposble dispose method', () => {
      jest.spyOn(instance.disposable, 'dispose');

      instance.dispose();

      expect(instance.disposable.dispose).toHaveBeenCalled();
    });

    it('resets instance', () => {
      instance.createInstance(document.createElement('div'));

      expect(instance.instance).not.toBeNull();

      instance.dispose();

      expect(instance.instance).toBeNull();
    });

    it('does not dispose modelManager', () => {
      jest.spyOn(instance.modelManager, 'dispose').mockImplementation(() => {});

      instance.dispose();

      expect(instance.modelManager.dispose).not.toHaveBeenCalled();
    });

    it('does not dispose decorationsController', () => {
      jest.spyOn(instance.decorationsController, 'dispose').mockImplementation(() => {});

      instance.dispose();

      expect(instance.decorationsController.dispose).not.toHaveBeenCalled();
    });
  });

  describe('updateDiffView', () => {
    describe('edit mode', () => {
      it('does not update options', () => {
        instance.createInstance(holder);

        jest.spyOn(instance.instance, 'updateOptions').mockImplementation(() => {});

        instance.updateDiffView();

        expect(instance.instance.updateOptions).not.toHaveBeenCalled();
      });
    });

    describe('diff mode', () => {
      beforeEach(() => {
        instance.createDiffInstance(holder);

        jest.spyOn(instance.instance, 'updateOptions');
      });

      it('sets renderSideBySide to false if el is less than 700 pixels', () => {
        setNodeOffsetWidth(600);

        expect(instance.instance.updateOptions).not.toHaveBeenCalledWith({
          renderSideBySide: false,
        });
      });

      it('sets renderSideBySide to false if el is more than 700 pixels', () => {
        setNodeOffsetWidth(800);

        expect(instance.instance.updateOptions).not.toHaveBeenCalledWith({
          renderSideBySide: true,
        });
      });
    });
  });

  describe('isDiffEditorType', () => {
    it('returns true when diff editor', () => {
      instance.createDiffInstance(holder);

      expect(instance.isDiffEditorType).toBe(true);
    });

    it('returns false when not diff editor', () => {
      instance.createInstance(holder);

      expect(instance.isDiffEditorType).toBe(false);
    });
  });

  it('sets quickSuggestions to false when language is markdown', () => {
    instance.createInstance(holder);

    jest.spyOn(instance.instance, 'updateOptions');

    const model = instance.createModel({
      ...file(),
      key: 'index.md',
      path: 'index.md',
    });

    instance.attachModel(model);

    expect(instance.instance.updateOptions).toHaveBeenCalledWith({
      readOnly: false,
      quickSuggestions: false,
    });
  });
});
