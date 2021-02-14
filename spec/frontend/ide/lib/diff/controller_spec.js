import { Range } from 'monaco-editor';
import ModelManager from '~/ide/lib/common/model_manager';
import DecorationsController from '~/ide/lib/decorations/controller';
import DirtyDiffController, { getDiffChangeType, getDecorator } from '~/ide/lib/diff/controller';
import { computeDiff } from '~/ide/lib/diff/diff';
import Editor from '~/ide/lib/editor';
import { createStore } from '~/ide/stores';
import { file } from '../../helpers';

describe('Multi-file editor library dirty diff controller', () => {
  let editorInstance;
  let controller;
  let modelManager;
  let decorationsController;
  let model;
  let store;

  beforeEach(() => {
    store = createStore();

    editorInstance = Editor.create(store);
    editorInstance.createInstance(document.createElement('div'));

    modelManager = new ModelManager();
    decorationsController = new DecorationsController(editorInstance);

    model = modelManager.addModel(file('path'));

    controller = new DirtyDiffController(modelManager, decorationsController);
  });

  afterEach(() => {
    controller.dispose();
    model.dispose();
    decorationsController.dispose();
    editorInstance.dispose();
  });

  describe('getDiffChangeType', () => {
    ['added', 'removed', 'modified'].forEach((type) => {
      it(`returns ${type}`, () => {
        const change = {
          [type]: true,
        };

        expect(getDiffChangeType(change)).toBe(type);
      });
    });
  });

  describe('getDecorator', () => {
    ['added', 'removed', 'modified'].forEach((type) => {
      it(`returns with linesDecorationsClassName for ${type}`, () => {
        const change = {
          [type]: true,
        };

        expect(getDecorator(change).options.linesDecorationsClassName).toBe(
          `dirty-diff dirty-diff-${type}`,
        );
      });

      it('returns with line numbers', () => {
        const change = {
          lineNumber: 1,
          endLineNumber: 2,
          [type]: true,
        };

        const { range } = getDecorator(change);

        expect(range.startLineNumber).toBe(1);
        expect(range.endLineNumber).toBe(2);
        expect(range.startColumn).toBe(1);
        expect(range.endColumn).toBe(1);
      });
    });
  });

  describe('attachModel', () => {
    it('adds change event callback', () => {
      jest.spyOn(model, 'onChange').mockImplementation(() => {});

      controller.attachModel(model);

      expect(model.onChange).toHaveBeenCalled();
    });

    it('adds dispose event callback', () => {
      jest.spyOn(model, 'onDispose').mockImplementation(() => {});

      controller.attachModel(model);

      expect(model.onDispose).toHaveBeenCalled();
    });

    it('calls throttledComputeDiff on change', () => {
      jest.spyOn(controller, 'throttledComputeDiff').mockImplementation(() => {});

      controller.attachModel(model);

      model.getModel().setValue('123');

      expect(controller.throttledComputeDiff).toHaveBeenCalled();
    });

    it('caches model', () => {
      controller.attachModel(model);

      expect(controller.models.has(model.url)).toBe(true);
    });
  });

  describe('computeDiff', () => {
    it('posts to worker', () => {
      jest.spyOn(controller.dirtyDiffWorker, 'postMessage').mockImplementation(() => {});

      controller.computeDiff(model);

      expect(controller.dirtyDiffWorker.postMessage).toHaveBeenCalledWith({
        path: model.path,
        originalContent: '',
        newContent: '',
      });
    });
  });

  describe('reDecorate', () => {
    it('calls computeDiff when no decorations are cached', () => {
      jest.spyOn(controller, 'computeDiff').mockImplementation(() => {});

      controller.reDecorate(model);

      expect(controller.computeDiff).toHaveBeenCalledWith(model);
    });

    it('calls decorate when decorations are cached', () => {
      jest.spyOn(controller.decorationsController, 'decorate').mockImplementation(() => {});

      controller.decorationsController.decorations.set(model.url, 'test');

      controller.reDecorate(model);

      expect(controller.decorationsController.decorate).toHaveBeenCalledWith(model);
    });
  });

  describe('decorate', () => {
    it('adds decorations into decorations controller', () => {
      jest.spyOn(controller.decorationsController, 'addDecorations').mockImplementation(() => {});

      controller.decorate({ data: { changes: [], path: model.path } });

      expect(controller.decorationsController.addDecorations).toHaveBeenCalledWith(
        model,
        'dirtyDiff',
        expect.anything(),
      );
    });

    it('adds decorations into editor', () => {
      const spy = jest.spyOn(controller.decorationsController.editor.instance, 'deltaDecorations');

      controller.decorate({
        data: { changes: computeDiff('123', '1234'), path: model.path },
      });

      expect(spy).toHaveBeenCalledWith(
        [],
        [
          {
            range: new Range(1, 1, 1, 1),
            options: {
              isWholeLine: true,
              linesDecorationsClassName: 'dirty-diff dirty-diff-modified',
            },
          },
        ],
      );
    });
  });

  describe('dispose', () => {
    it('calls disposable dispose', () => {
      jest.spyOn(controller.disposable, 'dispose');

      controller.dispose();

      expect(controller.disposable.dispose).toHaveBeenCalled();
    });

    it('terminates worker', () => {
      jest.spyOn(controller.dirtyDiffWorker, 'terminate');

      controller.dispose();

      expect(controller.dirtyDiffWorker.terminate).toHaveBeenCalled();
    });

    it('removes worker event listener', () => {
      jest.spyOn(controller.dirtyDiffWorker, 'removeEventListener');

      controller.dispose();

      expect(controller.dirtyDiffWorker.removeEventListener).toHaveBeenCalledWith(
        'message',
        expect.anything(),
      );
    });

    it('clears cached models', () => {
      controller.attachModel(model);

      model.dispose();

      expect(controller.models.size).toBe(0);
    });
  });
});
