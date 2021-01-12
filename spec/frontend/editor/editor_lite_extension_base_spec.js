import { ERROR_INSTANCE_REQUIRED_FOR_EXTENSION } from '~/editor/constants';
import { EditorLiteExtension } from '~/editor/extensions/editor_lite_extension_base';

describe('The basis for an Editor Lite extension', () => {
  let ext;
  const defaultOptions = { foo: 'bar' };

  it.each`
    description                                                     | instance     | options
    ${'accepts configuration options and instance'}                 | ${{}}        | ${defaultOptions}
    ${'leaves instance intact if no options are passed'}            | ${{}}        | ${undefined}
    ${'does not fail if both instance and the options are omitted'} | ${undefined} | ${undefined}
    ${'throws if only options are passed'}                          | ${undefined} | ${defaultOptions}
  `('$description', ({ instance, options } = {}) => {
    const originalInstance = { ...instance };

    if (instance) {
      if (options) {
        Object.entries(options).forEach((prop) => {
          expect(instance[prop]).toBeUndefined();
        });
        // Both instance and options are passed
        ext = new EditorLiteExtension({ instance, ...options });
        Object.entries(options).forEach(([prop, value]) => {
          expect(ext[prop]).toBeUndefined();
          expect(instance[prop]).toBe(value);
        });
      } else {
        ext = new EditorLiteExtension({ instance });
        expect(instance).toEqual(originalInstance);
      }
    } else if (options) {
      // Options are passed without instance
      expect(() => {
        ext = new EditorLiteExtension({ ...options });
      }).toThrow(ERROR_INSTANCE_REQUIRED_FOR_EXTENSION);
    } else {
      // Neither options nor instance are passed
      expect(() => {
        ext = new EditorLiteExtension();
      }).not.toThrow();
    }
  });
});
