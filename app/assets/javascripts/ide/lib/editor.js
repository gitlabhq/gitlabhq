import _ from 'underscore';
import DecorationsController from './decorations/controller';
import DirtyDiffController from './diff/controller';
import Disposable from './common/disposable';
import ModelManager from './common/model_manager';
import editorOptions, { defaultEditorOptions } from './editor_options';
import gitlabTheme from './themes/gl_theme';

export const clearDomElement = el => {
  if (!el || !el.firstChild) return;

  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }
};

export default class Editor {
  static create(monaco) {
    if (this.editorInstance) return this.editorInstance;

    this.editorInstance = new Editor(monaco);

    return this.editorInstance;
  }

  constructor(monaco) {
    this.monaco = monaco;
    this.currentModel = null;
    this.instance = null;
    this.dirtyDiffController = null;
    this.disposable = new Disposable();
    this.modelManager = new ModelManager(this.monaco);
    this.decorationsController = new DecorationsController(this);

    this.setupMonacoTheme();

    this.debouncedUpdate = _.debounce(() => {
      this.updateDimensions();
    }, 200);
  }

  createInstance(domElement) {
    if (!this.instance) {
      clearDomElement(domElement);

      this.disposable.add(
        (this.instance = this.monaco.editor.create(domElement, {
          ...defaultEditorOptions,
        })),
        (this.dirtyDiffController = new DirtyDiffController(
          this.modelManager,
          this.decorationsController,
        )),
      );

      window.addEventListener('resize', this.debouncedUpdate, false);
    }
  }

  createDiffInstance(domElement) {
    if (!this.instance) {
      clearDomElement(domElement);

      this.disposable.add(
        (this.instance = this.monaco.editor.createDiffEditor(domElement, {
          ...defaultEditorOptions,
          readOnly: true,
          quickSuggestions: false,
          occurrencesHighlight: false,
          renderLineHighlight: 'none',
          hideCursorInOverviewRuler: true,
          renderSideBySide: this.renderSideBySide(domElement),
        })),
      );

      window.addEventListener('resize', this.debouncedUpdate, false);
    }
  }

  createModel(file) {
    return this.modelManager.addModel(file);
  }

  attachModel(model) {
    if (this.isDiffEditorType) {
      this.instance.setModel({
        original: model.getOriginalModel(),
        modified: model.getModel(),
      });

      return;
    }

    this.instance.setModel(model.getModel());
    if (this.dirtyDiffController) this.dirtyDiffController.attachModel(model);

    this.currentModel = model;

    this.instance.updateOptions(
      editorOptions.reduce((acc, obj) => {
        Object.keys(obj).forEach(key => {
          Object.assign(acc, {
            [key]: obj[key](model),
          });
        });
        return acc;
      }, {}),
    );

    if (this.dirtyDiffController) this.dirtyDiffController.reDecorate(model);
  }

  attachMergeRequestModel(model) {
    this.instance.setModel({
      original: model.getBaseModel(),
      modified: model.getModel(),
    });

    this.monaco.editor.createDiffNavigator(this.instance, {
      alwaysRevealFirst: true,
    });
  }

  setupMonacoTheme() {
    this.monaco.editor.defineTheme(gitlabTheme.themeName, gitlabTheme.monacoTheme);

    this.monaco.editor.setTheme('gitlab');
  }

  clearEditor() {
    if (this.instance) {
      this.instance.setModel(null);
    }
  }

  dispose() {
    window.removeEventListener('resize', this.debouncedUpdate);

    // catch any potential errors with disposing the error
    // this is mainly for tests caused by elements not existing
    try {
      this.disposable.dispose();

      this.instance = null;
    } catch (e) {
      this.instance = null;

      if (process.env.NODE_ENV !== 'test') {
        // eslint-disable-next-line no-console
        console.error(e);
      }
    }
  }

  updateDimensions() {
    this.instance.layout();
    this.updateDiffView();
  }

  setPosition({ lineNumber, column }) {
    this.instance.revealPositionInCenter({
      lineNumber,
      column,
    });
    this.instance.setPosition({
      lineNumber,
      column,
    });
  }

  onPositionChange(cb) {
    if (!this.instance.onDidChangeCursorPosition) return;

    this.disposable.add(this.instance.onDidChangeCursorPosition(e => cb(this.instance, e)));
  }

  updateDiffView() {
    if (!this.isDiffEditorType) return;

    this.instance.updateOptions({
      renderSideBySide: this.renderSideBySide(this.instance.getDomNode()),
    });
  }

  get isDiffEditorType() {
    return this.instance.getEditorType() === 'vs.editor.IDiffEditor';
  }

  renderSideBySide(domElement) {
    return domElement.offsetWidth >= 700;
  }
}
