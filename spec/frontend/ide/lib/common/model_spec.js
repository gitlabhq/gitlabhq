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
    it('calls callback on change', () => {
      const spy = jest.fn();
      model.onChange(spy);

      model.getModel().setValue('123');

      expect(spy).toHaveBeenCalledWith(model, expect.anything());
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

    it('applies custom options and triggers onChange callback', () => {
      const changeSpy = jest.fn();
      jest.spyOn(model, 'applyCustomOptions');

      model.onChange(changeSpy);

      model.dispose();

      expect(model.applyCustomOptions).toHaveBeenCalled();
      expect(changeSpy).toHaveBeenCalled();
    });
  });

  describe('updateOptions', () => {
    it('sets the options on the options object', () => {
      model.updateOptions({ insertSpaces: true, someOption: 'some value' });

      expect(model.options).toEqual({
        insertFinalNewline: true,
        insertSpaces: true,
        someOption: 'some value',
        trimTrailingWhitespace: false,
      });
    });

    it.each`
      option            | value
      ${'insertSpaces'} | ${true}
      ${'insertSpaces'} | ${false}
      ${'indentSize'}   | ${4}
      ${'tabSize'}      | ${3}
    `("correctly sets option: $option=$value to Monaco's TextModel", ({ option, value }) => {
      model.updateOptions({ [option]: value });

      expect(model.getModel().getOptions()).toMatchObject({ [option]: value });
    });

    it('applies custom options immediately', () => {
      jest.spyOn(model, 'applyCustomOptions');

      model.updateOptions({ trimTrailingWhitespace: true, someOption: 'some value' });

      expect(model.applyCustomOptions).toHaveBeenCalled();
    });
  });

  describe('applyCustomOptions', () => {
    it.each`
      option                      | value    | contentBefore                   | contentAfter
      ${'insertFinalNewline'}     | ${true}  | ${'hello\nworld'}               | ${'hello\nworld\n'}
      ${'insertFinalNewline'}     | ${true}  | ${'hello\nworld\n'}             | ${'hello\nworld\n'}
      ${'insertFinalNewline'}     | ${false} | ${'hello\nworld'}               | ${'hello\nworld'}
      ${'trimTrailingWhitespace'} | ${true}  | ${'hello  \t\nworld  \t\n'}     | ${'hello\nworld\n'}
      ${'trimTrailingWhitespace'} | ${true}  | ${'hello  \t\r\nworld  \t\r\n'} | ${'hello\r\nworld\r\n'}
      ${'trimTrailingWhitespace'} | ${false} | ${'hello  \t\r\nworld  \t\r\n'} | ${'hello  \t\r\nworld  \t\r\n'}
    `(
      'correctly applies custom option $option=$value to content',
      ({ option, value, contentBefore, contentAfter }) => {
        model.options[option] = value;

        model.updateNewContent(contentBefore);
        model.applyCustomOptions();

        expect(model.getModel().getValue()).toEqual(contentAfter);
      },
    );
  });
});
