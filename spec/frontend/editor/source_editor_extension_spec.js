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
      expect(constructExtension).toThrow(EDITOR_EXTENSION_DEFINITION_ERROR);
    },
  );

  it.each`
    definition                  | setupOptions | expectedName
    ${helpers.SEClassExtension} | ${undefined} | ${'SEClassExtension'}
    ${helpers.SEClassExtension} | ${{}}        | ${'SEClassExtension'}
    ${helpers.SEClassExtension} | ${dummyObj}  | ${'SEClassExtension'}
    ${helpers.SEFnExtension}    | ${undefined} | ${'SEFnExtension'}
    ${helpers.SEFnExtension}    | ${{}}        | ${'SEFnExtension'}
    ${helpers.SEFnExtension}    | ${dummyObj}  | ${'SEFnExtension'}
    ${helpers.SEConstExt}       | ${undefined} | ${'SEConstExt'}
    ${helpers.SEConstExt}       | ${{}}        | ${'SEConstExt'}
    ${helpers.SEConstExt}       | ${dummyObj}  | ${'SEConstExt'}
  `(
    'correctly creates extension for definition = $definition and setupOptions = $setupOptions',
    ({ definition, setupOptions, expectedName }) => {
      const extension = new EditorExtension({ definition, setupOptions });
      // eslint-disable-next-line new-cap
      const constructedDefinition = new definition();

      expect(extension).toEqual(
        expect.objectContaining({
          extensionName: expectedName,
          setupOptions,
        }),
      );
      expect(extension.obj.constructor.prototype).toBe(constructedDefinition.constructor.prototype);
    },
  );

  describe('api', () => {
    it.each`
      definition                  | expectedKeys
      ${helpers.SEClassExtension} | ${['shared', 'classExtMethod']}
      ${helpers.SEFnExtension}    | ${['fnExtMethod']}
      ${helpers.SEConstExt}       | ${['constExtMethod']}
      ${helpers.SEExtWithoutAPI}  | ${[]}
    `('correctly returns API for $definition', ({ definition, expectedKeys }) => {
      const extension = new EditorExtension({ definition });
      const expectedApi = Object.fromEntries(
        expectedKeys.map((key) => [key, expect.any(Function)]),
      );
      expect(extension.api).toEqual(expect.objectContaining(expectedApi));
    });
  });
});
