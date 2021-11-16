import EditorExtension from '~/editor/source_editor_extension';
import { EDITOR_EXTENSION_DEFINITION_ERROR } from '~/editor/constants';
import * as helpers from './helpers';

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
    definition                  | setupOptions | expectedName
    ${helpers.MyClassExtension} | ${undefined} | ${'MyClassExtension'}
    ${helpers.MyClassExtension} | ${{}}        | ${'MyClassExtension'}
    ${helpers.MyClassExtension} | ${dummyObj}  | ${'MyClassExtension'}
    ${helpers.MyFnExtension}    | ${undefined} | ${'MyFnExtension'}
    ${helpers.MyFnExtension}    | ${{}}        | ${'MyFnExtension'}
    ${helpers.MyFnExtension}    | ${dummyObj}  | ${'MyFnExtension'}
    ${helpers.MyConstExt}       | ${undefined} | ${'MyConstExt'}
    ${helpers.MyConstExt}       | ${{}}        | ${'MyConstExt'}
    ${helpers.MyConstExt}       | ${dummyObj}  | ${'MyConstExt'}
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
      definition                  | expectedKeys
      ${helpers.MyClassExtension} | ${['shared', 'classExtMethod']}
      ${helpers.MyFnExtension}    | ${['fnExtMethod']}
      ${helpers.MyConstExt}       | ${['constExtMethod']}
    `('correctly returns API for $definition', ({ definition, expectedKeys }) => {
      const extension = new EditorExtension({ definition });
      const expectedApi = Object.fromEntries(
        expectedKeys.map((key) => [key, expect.any(Function)]),
      );
      expect(extension.api).toEqual(expect.objectContaining(expectedApi));
    });
  });
});
