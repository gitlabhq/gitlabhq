import { editor as monacoEditor } from 'monaco-editor';
import {
  EDITOR_EXTENSION_NAMING_CONFLICT_ERROR,
  EDITOR_EXTENSION_NO_DEFINITION_ERROR,
  EDITOR_EXTENSION_DEFINITION_TYPE_ERROR,
  EDITOR_EXTENSION_NOT_REGISTERED_ERROR,
  EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR,
} from '~/editor/constants';
import SourceEditorInstance from '~/editor/source_editor_instance';
import { sprintf } from '~/locale';
import {
  SEClassExtension,
  conflictingExtensions,
  SEFnExtension,
  SEConstExt,
  SEWithSetupExt,
} from './helpers';

describe('Source Editor Instance', () => {
  let seInstance;

  const defSetupOptions = { foo: 'bar' };
  const fullExtensionsArray = [
    { definition: SEClassExtension },
    { definition: SEFnExtension },
    { definition: SEConstExt },
  ];
  const fullExtensionsArrayWithOptions = [
    { definition: SEClassExtension, setupOptions: defSetupOptions },
    { definition: SEFnExtension, setupOptions: defSetupOptions },
    { definition: SEConstExt, setupOptions: defSetupOptions },
  ];

  const fooFn = jest.fn();
  const fooProp = 'foo';
  class DummyExt {
    // eslint-disable-next-line class-methods-use-this
    get extensionName() {
      return 'DummyExt';
    }
    // eslint-disable-next-line class-methods-use-this
    provides() {
      return {
        fooFn,
        fooProp,
      };
    }
  }

  afterEach(() => {
    seInstance = undefined;
  });

  it('sets up the registry for the methods coming from extensions', () => {
    seInstance = new SourceEditorInstance();
    expect(seInstance.methods).toBeDefined();

    seInstance.use({ definition: SEClassExtension });
    expect(seInstance.methods).toEqual({
      shared: 'SEClassExtension',
      classExtMethod: 'SEClassExtension',
    });

    seInstance.use({ definition: SEFnExtension });
    expect(seInstance.methods).toEqual({
      shared: 'SEClassExtension',
      classExtMethod: 'SEClassExtension',
      fnExtMethod: 'SEFnExtension',
    });
  });

  describe('proxy', () => {
    it('returns a method from an extension if extension provides it', () => {
      seInstance = new SourceEditorInstance();
      seInstance.use({ definition: DummyExt });

      expect(fooFn).not.toHaveBeenCalled();
      seInstance.fooFn();
      expect(fooFn).toHaveBeenCalled();
    });

    it('returns a prop from an extension if extension provides it', () => {
      seInstance = new SourceEditorInstance();
      seInstance.use({ definition: DummyExt });

      expect(seInstance.fooProp).toBe('foo');
    });

    it.each`
      stringPropToPass | objPropToPass        | setupOptions
      ${undefined}     | ${undefined}         | ${undefined}
      ${'prop'}        | ${undefined}         | ${undefined}
      ${'prop'}        | ${[]}                | ${undefined}
      ${'prop'}        | ${{}}                | ${undefined}
      ${'prop'}        | ${{ alpha: 'beta' }} | ${undefined}
      ${'prop'}        | ${{ alpha: 'beta' }} | ${defSetupOptions}
      ${'prop'}        | ${undefined}         | ${defSetupOptions}
      ${undefined}     | ${undefined}         | ${defSetupOptions}
      ${''}            | ${{}}                | ${defSetupOptions}
    `(
      'correctly passes arguments ("$stringPropToPass", "$objPropToPass") and instance (with "$setupOptions" setupOptions) to extension methods',
      ({ stringPropToPass, objPropToPass, setupOptions }) => {
        seInstance = new SourceEditorInstance();
        seInstance.use({ definition: SEWithSetupExt, setupOptions });

        const [stringProp, objProp, instance] = seInstance.returnInstanceAndProps(
          stringPropToPass,
          objPropToPass,
        );
        const expectedObjProps = objPropToPass || {};

        expect(instance).toBe(seInstance);
        expect(stringProp).toBe(stringPropToPass);
        expect(objProp).toEqual(expectedObjProps);
        if (setupOptions) {
          Object.keys(setupOptions).forEach((key) => {
            expect(instance[key]).toBe(setupOptions[key]);
          });
        }
      },
    );

    it('correctly passes instance to the methods even if no additional props have been passed', () => {
      seInstance = new SourceEditorInstance();
      seInstance.use({ definition: SEWithSetupExt });

      const instance = seInstance.returnInstance();

      expect(instance).toBe(seInstance);
    });

    it("correctly sets the context of the 'this' keyword for the extension's methods", () => {
      seInstance = new SourceEditorInstance();
      const extension = seInstance.use({ definition: SEWithSetupExt });

      expect(seInstance.giveMeContext()).toEqual(extension.obj);
    });

    it('returns props from SE instance itself if no extension provides the prop', () => {
      seInstance = new SourceEditorInstance({
        use: fooFn,
      });
      const spy = jest.spyOn(seInstance.constructor.prototype, 'use').mockImplementation(() => {});
      expect(spy).not.toHaveBeenCalled();
      expect(fooFn).not.toHaveBeenCalled();
      seInstance.use();
      expect(spy).toHaveBeenCalled();
      expect(fooFn).not.toHaveBeenCalled();
    });

    it('returns props from Monaco instance when the prop does not exist on the SE instance', () => {
      seInstance = new SourceEditorInstance({
        fooFn,
      });

      expect(fooFn).not.toHaveBeenCalled();
      seInstance.fooFn();
      expect(fooFn).toHaveBeenCalled();
    });
  });

  describe('public API', () => {
    it.each(['use', 'unuse'])('provides "%s" as public method by default', (method) => {
      seInstance = new SourceEditorInstance();
      expect(seInstance[method]).toBeDefined();
    });

    describe('use', () => {
      it('extends the SE instance with methods provided by an extension', () => {
        seInstance = new SourceEditorInstance();
        seInstance.use({ definition: DummyExt });

        expect(fooFn).not.toHaveBeenCalled();
        seInstance.fooFn();
        expect(fooFn).toHaveBeenCalled();
      });

      it.each`
        extensions                          | expectedProps
        ${{ definition: SEClassExtension }} | ${['shared', 'classExtMethod']}
        ${{ definition: SEFnExtension }}    | ${['fnExtMethod']}
        ${{ definition: SEConstExt }}       | ${['constExtMethod']}
        ${fullExtensionsArray}              | ${['shared', 'classExtMethod', 'fnExtMethod', 'constExtMethod']}
        ${fullExtensionsArrayWithOptions}   | ${['shared', 'classExtMethod', 'fnExtMethod', 'constExtMethod']}
      `(
        'Should register $expectedProps when extension is "$extensions"',
        ({ extensions, expectedProps }) => {
          seInstance = new SourceEditorInstance();
          expect(seInstance.extensionsAPI).toHaveLength(0);

          seInstance.use(extensions);

          expect(seInstance.extensionsAPI).toEqual(expectedProps);
        },
      );

      it.each`
        definition                               | preInstalledExtDefinition               | expectedErrorProp
        ${conflictingExtensions.WithInstanceExt} | ${SEClassExtension}                     | ${'use'}
        ${conflictingExtensions.WithInstanceExt} | ${null}                                 | ${'use'}
        ${conflictingExtensions.WithAnotherExt}  | ${null}                                 | ${undefined}
        ${conflictingExtensions.WithAnotherExt}  | ${SEClassExtension}                     | ${'shared'}
        ${SEClassExtension}                      | ${conflictingExtensions.WithAnotherExt} | ${'shared'}
      `(
        'logs the naming conflict error when registering $definition',
        ({ definition, preInstalledExtDefinition, expectedErrorProp }) => {
          seInstance = new SourceEditorInstance();
          jest.spyOn(console, 'error').mockImplementation(() => {});

          if (preInstalledExtDefinition) {
            seInstance.use({ definition: preInstalledExtDefinition });
            // eslint-disable-next-line no-console
            expect(console.error).not.toHaveBeenCalled();
          }

          seInstance.use({ definition });

          if (expectedErrorProp) {
            // eslint-disable-next-line no-console
            expect(console.error).toHaveBeenCalledWith(
              expect.any(String),
              expect.stringContaining(
                sprintf(EDITOR_EXTENSION_NAMING_CONFLICT_ERROR, { prop: expectedErrorProp }),
              ),
            );
          } else {
            // eslint-disable-next-line no-console
            expect(console.error).not.toHaveBeenCalled();
          }
        },
      );

      it.each`
        extensions                        | thrownError
        ${''}                             | ${EDITOR_EXTENSION_NO_DEFINITION_ERROR}
        ${undefined}                      | ${EDITOR_EXTENSION_NO_DEFINITION_ERROR}
        ${{}}                             | ${EDITOR_EXTENSION_NO_DEFINITION_ERROR}
        ${{ foo: 'bar' }}                 | ${EDITOR_EXTENSION_NO_DEFINITION_ERROR}
        ${{ definition: '' }}             | ${EDITOR_EXTENSION_NO_DEFINITION_ERROR}
        ${{ definition: undefined }}      | ${EDITOR_EXTENSION_NO_DEFINITION_ERROR}
        ${{ definition: [] }}             | ${EDITOR_EXTENSION_DEFINITION_TYPE_ERROR}
        ${{ definition: {} }}             | ${EDITOR_EXTENSION_DEFINITION_TYPE_ERROR}
        ${{ definition: { foo: 'bar' } }} | ${EDITOR_EXTENSION_DEFINITION_TYPE_ERROR}
      `(
        'Should throw $thrownError when extension is "$extensions"',
        ({ extensions, thrownError }) => {
          seInstance = new SourceEditorInstance();
          const useExtension = () => {
            seInstance.use(extensions);
          };
          expect(useExtension).toThrow(thrownError);
        },
      );

      describe('global extensions registry', () => {
        let extensionStore;

        beforeEach(() => {
          extensionStore = new Map();
          seInstance = new SourceEditorInstance({}, extensionStore);
        });

        it('stores _instances_ of the used extensions in a global registry', () => {
          const extension = seInstance.use({ definition: SEClassExtension });

          expect(extensionStore.size).toBe(1);
          expect(extensionStore.entries().next().value).toEqual(['SEClassExtension', extension]);
        });

        it('does not duplicate entries in the registry', () => {
          jest.spyOn(extensionStore, 'set');

          const extension1 = seInstance.use({ definition: SEClassExtension });
          seInstance.use({ definition: SEClassExtension });

          expect(extensionStore.set).toHaveBeenCalledTimes(1);
          expect(extensionStore.set).toHaveBeenCalledWith('SEClassExtension', extension1);
        });

        it('correctly registers methods from the existing extension on an instance', () => {
          const seInstance2 = new SourceEditorInstance({}, extensionStore);
          seInstance.use({ definition: SEClassExtension });
          const val1 = seInstance.classExtMethod();

          seInstance2.use({ definition: SEClassExtension });

          expect(seInstance2.classExtMethod).toBeDefined();
          expect(seInstance2.classExtMethod()).toBe(val1); // from helpers.js we know classExtMethod()returns a string. Hence `toBe`
        });

        it.each`
          desc                 | currentSetupOptions | newSetupOptions    | expectedCallTimes
          ${'updates'}         | ${undefined}        | ${defSetupOptions} | ${2}
          ${'updates'}         | ${defSetupOptions}  | ${undefined}       | ${2}
          ${'updates'}         | ${{ foo: 'bar' }}   | ${{ foo: 'new' }}  | ${2}
          ${'does not update'} | ${undefined}        | ${undefined}       | ${1}
          ${'does not update'} | ${{}}               | ${{}}              | ${1}
          ${'does not update'} | ${defSetupOptions}  | ${defSetupOptions} | ${1}
        `(
          '$desc the extensions entry when setupOptions "$currentSetupOptions" get changed to "$newSetupOptions"',
          ({ currentSetupOptions, newSetupOptions, expectedCallTimes }) => {
            jest.spyOn(extensionStore, 'set');

            const extension1 = seInstance.use({
              definition: SEClassExtension,
              setupOptions: currentSetupOptions,
            });
            const extension2 = seInstance.use({
              definition: SEClassExtension,
              setupOptions: newSetupOptions,
            });

            expect(extensionStore.size).toBe(1);
            expect(extensionStore.set).toHaveBeenCalledTimes(expectedCallTimes);
            if (expectedCallTimes > 1) {
              expect(extensionStore.set).toHaveBeenCalledWith('SEClassExtension', extension2);
            } else {
              expect(extensionStore.set).toHaveBeenCalledWith('SEClassExtension', extension1);
            }
          },
        );
      });
    });

    describe('unuse', () => {
      it.each`
        unuseExtension | thrownError
        ${undefined}   | ${EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR}
        ${''}          | ${EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR}
        ${{}}          | ${sprintf(EDITOR_EXTENSION_NOT_REGISTERED_ERROR, { name: '' })}
        ${[]}          | ${EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR}
      `(
        `Should throw "${EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR}" when extension is "$unuseExtension"`,
        ({ unuseExtension, thrownError }) => {
          seInstance = new SourceEditorInstance();
          const unuse = () => {
            seInstance.unuse(unuseExtension);
          };
          expect(unuse).toThrow(thrownError);
        },
      );

      it.each`
        initExtensions                      | unuseExtensionIndex | remainingAPI
        ${{ definition: SEClassExtension }} | ${0}                | ${[]}
        ${{ definition: SEFnExtension }}    | ${0}                | ${[]}
        ${{ definition: SEConstExt }}       | ${0}                | ${[]}
        ${fullExtensionsArray}              | ${0}                | ${['fnExtMethod', 'constExtMethod']}
        ${fullExtensionsArray}              | ${1}                | ${['shared', 'classExtMethod', 'constExtMethod']}
        ${fullExtensionsArray}              | ${2}                | ${['shared', 'classExtMethod', 'fnExtMethod']}
      `(
        'un-registers properties introduced by single extension $unuseExtension',
        ({ initExtensions, unuseExtensionIndex, remainingAPI }) => {
          seInstance = new SourceEditorInstance();
          const extensions = seInstance.use(initExtensions);

          if (Array.isArray(initExtensions)) {
            seInstance.unuse(extensions[unuseExtensionIndex]);
          } else {
            seInstance.unuse(extensions);
          }
          expect(seInstance.extensionsAPI).toEqual(remainingAPI);
        },
      );

      it.each`
        unuseExtensionIndex | remainingAPI
        ${[0, 1]}           | ${['constExtMethod']}
        ${[0, 2]}           | ${['fnExtMethod']}
        ${[1, 2]}           | ${['shared', 'classExtMethod']}
      `(
        'un-registers properties introduced by multiple extensions $unuseExtension',
        ({ unuseExtensionIndex, remainingAPI }) => {
          seInstance = new SourceEditorInstance();
          const extensions = seInstance.use(fullExtensionsArray);
          const extensionsToUnuse = extensions.filter((ext, index) =>
            unuseExtensionIndex.includes(index),
          );

          seInstance.unuse(extensionsToUnuse);
          expect(seInstance.extensionsAPI).toEqual(remainingAPI);
        },
      );

      it('does not remove entry from the global registry to keep for potential future re-use', () => {
        const extensionStore = new Map();
        seInstance = new SourceEditorInstance({}, extensionStore);
        const extensions = seInstance.use(fullExtensionsArray);
        const verifyExpectations = () => {
          const entries = extensionStore.entries();
          const mockExtensions = ['SEClassExtension', 'SEFnExtension', 'SEConstExt'];
          expect(extensionStore.size).toBe(mockExtensions.length);
          mockExtensions.forEach((ext, index) => {
            expect(entries.next().value).toEqual([ext, extensions[index]]);
          });
        };

        verifyExpectations();
        seInstance.unuse(extensions);
        verifyExpectations();
      });
    });

    describe('updateModelLanguage', () => {
      let instanceModel;

      beforeEach(() => {
        instanceModel = monacoEditor.createModel('');
        seInstance = new SourceEditorInstance({
          getModel: () => instanceModel,
        });
      });

      it.each`
        path                     | expectedLanguage
        ${'foo.js'}              | ${'javascript'}
        ${'foo.md'}              | ${'markdown'}
        ${'foo.rb'}              | ${'ruby'}
        ${''}                    | ${'plaintext'}
        ${undefined}             | ${'plaintext'}
        ${'test.nonexistingext'} | ${'plaintext'}
      `(
        'changes language of an attached model to "$expectedLanguage" when filepath is "$path"',
        ({ path, expectedLanguage }) => {
          seInstance.updateModelLanguage(path);
          expect(instanceModel.getLanguageId()).toBe(expectedLanguage);
        },
      );
    });

    describe('extensions life-cycle callbacks', () => {
      const onSetup = jest.fn().mockImplementation(() => {});
      const onUse = jest.fn().mockImplementation(() => {});
      const onBeforeUnuse = jest.fn().mockImplementation(() => {});
      const onUnuse = jest.fn().mockImplementation(() => {});
      const MyFullExtWithCallbacks = () => {
        return {
          onSetup,
          onUse,
          onBeforeUnuse,
          onUnuse,
        };
      };

      it('passes correct arguments to callback fns when using an extension', () => {
        seInstance = new SourceEditorInstance();
        seInstance.use({
          definition: MyFullExtWithCallbacks,
          setupOptions: defSetupOptions,
        });
        expect(onSetup).toHaveBeenCalledWith(seInstance, defSetupOptions);
        expect(onUse).toHaveBeenCalledWith(seInstance);
      });

      it('passes correct arguments to callback fns when un-using an extension', () => {
        seInstance = new SourceEditorInstance();
        const extension = seInstance.use({
          definition: MyFullExtWithCallbacks,
          setupOptions: defSetupOptions,
        });
        seInstance.unuse(extension);
        expect(onBeforeUnuse).toHaveBeenCalledWith(seInstance);
        expect(onUnuse).toHaveBeenCalledWith(seInstance);
      });
    });
  });
});
