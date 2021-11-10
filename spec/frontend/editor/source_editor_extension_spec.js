import EditorExtension from '~/editor/source_editor_extension';
import { EDITOR_EXTENSION_DEFINITION_ERROR } from '~/editor/constants';

class MyClassExtension {
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      shared: () => 'extension',
      classExtMethod: () => 'class own method',
    };
  }
}

function MyFnExtension() {
  return {
    fnExtMethod: () => 'fn own method',
    provides: () => {
      return {
        shared: () => 'extension',
      };
    },
  };
}

const MyConstExt = () => {
  return {
    provides: () => {
      return {
        shared: () => 'extension',
        constExtMethod: () => 'const own method',
      };
    },
  };
};

describe('Editor Extension', () => {
  const dummyObj = { foo: 'bar' };

  it.each`
    definition   | setupOptions
    ${undefined} | ${undefined}
    ${undefined} | ${{}}
    ${undefined} | ${dummyObj}
    ${{}}        | ${dummyObj}
    ${dummyObj}  | ${dummyObj}
  `(
    'throws when definition = $definition and setupOptions = $setupOptions',
    ({ definition, setupOptions }) => {
      const constructExtension = () => new EditorExtension({ definition, setupOptions });
      expect(constructExtension).toThrowError(EDITOR_EXTENSION_DEFINITION_ERROR);
    },
  );

  it.each`
    definition          | setupOptions | expectedName
    ${MyClassExtension} | ${undefined} | ${'MyClassExtension'}
    ${MyClassExtension} | ${{}}        | ${'MyClassExtension'}
    ${MyClassExtension} | ${dummyObj}  | ${'MyClassExtension'}
    ${MyFnExtension}    | ${undefined} | ${'MyFnExtension'}
    ${MyFnExtension}    | ${{}}        | ${'MyFnExtension'}
    ${MyFnExtension}    | ${dummyObj}  | ${'MyFnExtension'}
    ${MyConstExt}       | ${undefined} | ${'MyConstExt'}
    ${MyConstExt}       | ${{}}        | ${'MyConstExt'}
    ${MyConstExt}       | ${dummyObj}  | ${'MyConstExt'}
  `(
    'correctly creates extension for definition = $definition and setupOptions = $setupOptions',
    ({ definition, setupOptions, expectedName }) => {
      const extension = new EditorExtension({ definition, setupOptions });
      // eslint-disable-next-line new-cap
      const constructedDefinition = new definition();

      expect(extension).toEqual(
        expect.objectContaining({
          name: expectedName,
          setupOptions,
        }),
      );
      expect(extension.obj.constructor.prototype).toBe(constructedDefinition.constructor.prototype);
    },
  );

  describe('api', () => {
    it.each`
      definition          | expectedKeys
      ${MyClassExtension} | ${['shared', 'classExtMethod']}
      ${MyFnExtension}    | ${['shared']}
      ${MyConstExt}       | ${['shared', 'constExtMethod']}
    `('correctly returns API for $definition', ({ definition, expectedKeys }) => {
      const extension = new EditorExtension({ definition });
      const expectedApi = Object.fromEntries(
        expectedKeys.map((key) => [key, expect.any(Function)]),
      );
      expect(extension.api).toEqual(expect.objectContaining(expectedApi));
    });
  });
});
