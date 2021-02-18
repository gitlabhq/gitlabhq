import Model from '~/ide/lib/common/model';
import DecorationsController from '~/ide/lib/decorations/controller';
import Editor from '~/ide/lib/editor';
import { createStore } from '~/ide/stores';
import { file } from '../../helpers';

describe('Multi-file editor library decorations controller', () => {
  let editorInstance;
  let controller;
  let model;
  let store;

  beforeEach(() => {
    store = createStore();
    editorInstance = Editor.create(store);
    editorInstance.createInstance(document.createElement('div'));

    controller = new DecorationsController(editorInstance);
    model = new Model(file('path'));
  });

  afterEach(() => {
    model.dispose();
    editorInstance.dispose();
    controller.dispose();
  });

  describe('getAllDecorationsForModel', () => {
    it('returns empty array when no decorations exist for model', () => {
      const decorations = controller.getAllDecorationsForModel(model);

      expect(decorations).toEqual([]);
    });

    it('returns decorations by model URL', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      const decorations = controller.getAllDecorationsForModel(model);

      expect(decorations[0]).toEqual({ decoration: 'decorationValue' });
    });
  });

  describe('addDecorations', () => {
    it('caches decorations in a new map', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      expect(controller.decorations.size).toBe(1);
    });

    it('does not create new cache model', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue2' }]);

      expect(controller.decorations.size).toBe(1);
    });

    it('caches decorations by model URL', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      expect(controller.decorations.size).toBe(1);
      expect(controller.decorations.keys().next().value).toBe('gitlab:path--path');
    });

    it('calls decorate method', () => {
      jest.spyOn(controller, 'decorate').mockImplementation(() => {});

      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      expect(controller.decorate).toHaveBeenCalled();
    });
  });

  describe('decorate', () => {
    it('sets decorations on editor instance', () => {
      jest.spyOn(controller.editor.instance, 'deltaDecorations').mockImplementation(() => {});

      controller.decorate(model);

      expect(controller.editor.instance.deltaDecorations).toHaveBeenCalledWith([], []);
    });

    it('caches decorations', () => {
      jest.spyOn(controller.editor.instance, 'deltaDecorations').mockReturnValue([]);

      controller.decorate(model);

      expect(controller.editorDecorations.size).toBe(1);
    });

    it('caches decorations by model URL', () => {
      jest.spyOn(controller.editor.instance, 'deltaDecorations').mockReturnValue([]);

      controller.decorate(model);

      expect(controller.editorDecorations.keys().next().value).toBe('gitlab:path--path');
    });
  });

  describe('dispose', () => {
    it('clears cached decorations', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      controller.dispose();

      expect(controller.decorations.size).toBe(0);
    });

    it('clears cached editorDecorations', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      controller.dispose();

      expect(controller.editorDecorations.size).toBe(0);
    });
  });

  describe('hasDecorations', () => {
    it('returns true when decorations are cached', () => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);

      expect(controller.hasDecorations(model)).toBe(true);
    });

    it('returns false when no model decorations exist', () => {
      expect(controller.hasDecorations(model)).toBe(false);
    });
  });

  describe('removeDecorations', () => {
    beforeEach(() => {
      controller.addDecorations(model, 'key', [{ decoration: 'decorationValue' }]);
      controller.decorate(model);
    });

    it('removes cached decorations', () => {
      expect(controller.decorations.size).not.toBe(0);
      expect(controller.editorDecorations.size).not.toBe(0);

      controller.removeDecorations(model);

      expect(controller.decorations.size).toBe(0);
      expect(controller.editorDecorations.size).toBe(0);
    });
  });
});
