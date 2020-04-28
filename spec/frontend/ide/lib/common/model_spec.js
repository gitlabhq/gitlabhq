import eventHub from '~/ide/eventhub';
import Model from '~/ide/lib/common/model';
import { file } from '../../helpers';

describe('Multi-file editor library model', () => {
  let model;

  beforeEach(() => {
    jest.spyOn(eventHub, '$on');

    const f = file('path');
    f.mrChange = { diff: 'ABC' };
    f.baseRaw = 'test';
    model = new Model(f);
  });

  afterEach(() => {
    model.dispose();
  });

  it('creates original model & base model & new model', () => {
    expect(model.originalModel).not.toBeNull();
    expect(model.model).not.toBeNull();
    expect(model.baseModel).not.toBeNull();

    expect(model.originalModel.uri.path).toBe('original/path--path');
    expect(model.model.uri.path).toBe('path--path');
    expect(model.baseModel.uri.path).toBe('target/path--path');
  });

  it('creates model with head file to compare against', () => {
    const f = file('path');
    model.dispose();

    model = new Model(f, {
      ...f,
      content: '123 testing',
    });

    expect(model.head).not.toBeNull();
    expect(model.getOriginalModel().getValue()).toBe('123 testing');
  });

  it('adds eventHub listener', () => {
    expect(eventHub.$on).toHaveBeenCalledWith(
      `editor.update.model.dispose.${model.file.key}`,
      expect.anything(),
    );
  });

  describe('path', () => {
    it('returns file path', () => {
      expect(model.path).toBe(model.file.key);
    });
  });

  describe('getModel', () => {
    it('returns model', () => {
      expect(model.getModel()).toBe(model.model);
    });
  });

  describe('getOriginalModel', () => {
    it('returns original model', () => {
      expect(model.getOriginalModel()).toBe(model.originalModel);
    });
  });

  describe('getBaseModel', () => {
    it('returns base model', () => {
      expect(model.getBaseModel()).toBe(model.baseModel);
    });
  });

  describe('setValue', () => {
    it('updates models value', () => {
      model.setValue('testing 123');

      expect(model.getModel().getValue()).toBe('testing 123');
    });
  });

  describe('onChange', () => {
    it('calls callback on change', done => {
      const spy = jest.fn();
      model.onChange(spy);

      model.getModel().setValue('123');

      setImmediate(() => {
        expect(spy).toHaveBeenCalledWith(model, expect.anything());
        done();
      });
    });
  });

  describe('dispose', () => {
    it('calls disposable dispose', () => {
      jest.spyOn(model.disposable, 'dispose');

      model.dispose();

      expect(model.disposable.dispose).toHaveBeenCalled();
    });

    it('clears events', () => {
      model.onChange(() => {});

      expect(model.events.size).toBe(1);

      model.dispose();

      expect(model.events.size).toBe(0);
    });

    it('removes eventHub listener', () => {
      jest.spyOn(eventHub, '$off');

      model.dispose();

      expect(eventHub.$off).toHaveBeenCalledWith(
        `editor.update.model.dispose.${model.file.key}`,
        expect.anything(),
      );
    });

    it('calls onDispose callback', () => {
      const disposeSpy = jest.fn();

      model.onDispose(disposeSpy);

      model.dispose();

      expect(disposeSpy).toHaveBeenCalled();
    });
  });
});
