import { editor as monacoEditor } from 'monaco-editor';
import {
  EDITOR_EXTENSION_NAMING_CONFLICT_ERROR,
  EDITOR_EXTENSION_NO_DEFINITION_ERROR,
  EDITOR_EXTENSION_DEFINITION_TYPE_ERROR,
  EDITOR_EXTENSION_NOT_REGISTERED_ERROR,
  EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR,
} from '~/editor/constants';
import Instance from '~/editor/source_editor_instance';
import { sprintf } from '~/locale';
import { MyClassExtension, conflictingExtensions, MyFnExtension, MyConstExt } from './helpers';

describe('Source Editor Instance', () => {
  let seInstance;

  const defSetupOptions = { foo: 'bar' };
  const fullExtensionsArray = [
    { definition: MyClassExtension },
    { definition: MyFnExtension },
    { definition: MyConstExt },
  ];
  const fullExtensionsArrayWithOptions = [
    { definition: MyClassExtension, setupOptions: defSetupOptions },
    { definition: MyFnExtension, setupOptions: defSetupOptions },
    { definition: MyConstExt, setupOptions: defSetupOptions },
  ];

  const fooFn = jest.fn();
  class DummyExt {
    // eslint-disable-next-line class-methods-use-this
    provides() {
      return {
        fooFn,
      };
    }
  }

  afterEach(() => {
    seInstance = undefined;
  });

  it('sets up the registry for the methods coming from extensions', () => {
    seInstance = new Instance();
    expect(seInstance.methods).toBeDefined();

    seInstance.use({ definition: MyClassExtension });
    expect(seInstance.methods).toEqual({
      shared: 'MyClassExtension',
      classExtMethod: 'MyClassExtension',
    });

    seInstance.use({ definition: MyFnExtension });
    expect(seInstance.methods).toEqual({
      shared: 'MyClassExtension',
      classExtMethod: 'MyClassExtension',
      fnExtMethod: 'MyFnExtension',
    });
  });

  describe('proxy', () => {
    it('returns prop from an extension if extension provides it', () => {
      seInstance = new Instance();
      seInstance.use({ definition: DummyExt });

      expect(fooFn).not.toHaveBeenCalled();
      seInstance.fooFn();
      expect(fooFn).toHaveBeenCalled();
    });

    it('returns props from SE instance itself if no extension provides the prop', () => {
      seInstance = new Instance({
        use: fooFn,
      });
      jest.spyOn(seInstance, 'use').mockImplementation(() => {});
      expect(seInstance.use).not.toHaveBeenCalled();
      expect(fooFn).not.toHaveBeenCalled();
      seInstance.use();
      expect(seInstance.use).toHaveBeenCalled();
      expect(fooFn).not.toHaveBeenCalled();
    });

    it('returns props from Monaco instance when the prop does not exist on the SE instance', () => {
      seInstance = new Instance({
        fooFn,
      });

      expect(fooFn).not.toHaveBeenCalled();
      seInstance.fooFn();
      expect(fooFn).toHaveBeenCalled();
    });
  });

  describe('public API', () => {
    it.each(['use', 'unuse'], 'provides "%s" as public method by default', (method) => {
      seInstance = new Instance();
      expect(seInstance[method]).toBeDefined();
    });

    describe('use', () => {
      it('extends the SE instance with methods provided by an extension', () => {
        seInstance = new Instance();
        seInstance.use({ definition: DummyExt });

        expect(fooFn).not.toHaveBeenCalled();
        seInstance.fooFn();
        expect(fooFn).toHaveBeenCalled();
      });

      it.each`
        extensions                          | expectedProps
        ${{ definition: MyClassExtension }} | ${['shared', 'classExtMethod']}
        ${{ definition: MyFnExtension }}    | ${['fnExtMethod']}
        ${{ definition: MyConstExt }}       | ${['constExtMethod']}
        ${fullExtensionsArray}              | ${['shared', 'classExtMethod', 'fnExtMethod', 'constExtMethod']}
        ${fullExtensionsArrayWithOptions}   | ${['shared', 'classExtMethod', 'fnExtMethod', 'constExtMethod']}
      `(
        'Should register $expectedProps when extension is "$extensions"',
        ({ extensions, expectedProps }) => {
          seInstance = new Instance();
          expect(seInstance.extensionsAPI).toHaveLength(0);

          seInstance.use(extensions);

          expect(seInstance.extensionsAPI).toEqual(expectedProps);
        },
      );

      it.each`
        definition                               | preInstalledExtDefinition               | expectedErrorProp
        ${conflictingExtensions.WithInstanceExt} | ${MyClassExtension}                     | ${'use'}
        ${conflictingExtensions.WithInstanceExt} | ${null}                                 | ${'use'}
        ${conflictingExtensions.WithAnotherExt}  | ${null}                                 | ${undefined}
        ${conflictingExtensions.WithAnotherExt}  | ${MyClassExtension}                     | ${'shared'}
        ${MyClassExtension}                      | ${conflictingExtensions.WithAnotherExt} | ${'shared'}
      `(
        'logs the naming conflict error when registering $definition',
        ({ definition, preInstalledExtDefinition, expectedErrorProp }) => {
          seInstance = new Instance();
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
          seInstance = new Instance();
          const useExtension = () => {
            seInstance.use(extensions);
          };
          expect(useExtension).toThrowError(thrownError);
        },
      );

      describe('global extensions registry', () => {
        let extensionStore;

        beforeEach(() => {
          extensionStore = new Map();
          seInstance = new Instance({}, extensionStore);
        });

        it('stores _instances_ of the used extensions in a global registry', () => {
          const extension = seInstance.use({ definition: MyClassExtension });

          expect(extensionStore.size).toBe(1);
          expect(extensionStore.entries().next().value).toEqual(['MyClassExtension', extension]);
        });

        it('does not duplicate entries in the registry', () => {
          jest.spyOn(extensionStore, 'set');

          const extension1 = seInstance.use({ definition: MyClassExtension });
          seInstance.use({ definition: MyClassExtension });

          expect(extensionStore.set).toHaveBeenCalledTimes(1);
          expect(extensionStore.set).toHaveBeenCalledWith('MyClassExtension', extension1);
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
              definition: MyClassExtension,
              setupOptions: currentSetupOptions,
            });
            const extension2 = seInstance.use({
              definition: MyClassExtension,
              setupOptions: newSetupOptions,
            });

            expect(extensionStore.size).toBe(1);
            expect(extensionStore.set).toHaveBeenCalledTimes(expectedCallTimes);
            if (expectedCallTimes > 1) {
              expect(extensionStore.set).toHaveBeenCalledWith('MyClassExtension', extension2);
            } else {
              expect(extensionStore.set).toHaveBeenCalledWith('MyClassExtension', extension1);
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
          seInstance = new Instance();
          const unuse = () => {
            seInstance.unuse(unuseExtension);
          };
          expect(unuse).toThrowError(thrownError);
        },
      );

      it.each`
        initExtensions                      | unuseExtensionIndex | remainingAPI
        ${{ definition: MyClassExtension }} | ${0}                | ${[]}
        ${{ definition: MyFnExtension }}    | ${0}                | ${[]}
        ${{ definition: MyConstExt }}       | ${0}                | ${[]}
        ${fullExtensionsArray}              | ${0}                | ${['fnExtMethod', 'constExtMethod']}
        ${fullExtensionsArray}              | ${1}                | ${['shared', 'classExtMethod', 'constExtMethod']}
        ${fullExtensionsArray}              | ${2}                | ${['shared', 'classExtMethod', 'fnExtMethod']}
      `(
        'un-registers properties introduced by single extension $unuseExtension',
        ({ initExtensions, unuseExtensionIndex, remainingAPI }) => {
          seInstance = new Instance();
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
          seInstance = new Instance();
          const extensions = seInstance.use(fullExtensionsArray);
          const extensionsToUnuse = extensions.filter((ext, index) =>
            unuseExtensionIndex.includes(index),
          );

          seInstance.unuse(extensionsToUnuse);
          expect(seInstance.extensionsAPI).toEqual(remainingAPI);
        },
      );

      it('it does not remove entry from the global registry to keep for potential future re-use', () => {
        const extensionStore = new Map();
        seInstance = new Instance({}, extensionStore);
        const extensions = seInstance.use(fullExtensionsArray);
        const verifyExpectations = () => {
          const entries = extensionStore.entries();
          const mockExtensions = ['MyClassExtension', 'MyFnExtension', 'MyConstExt'];
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
        seInstance = new Instance({
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
          expect(instanceModel.getLanguageIdentifier().language).toBe(expectedLanguage);
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
        seInstance = new Instance();
        seInstance.use({
          definition: MyFullExtWithCallbacks,
          setupOptions: defSetupOptions,
        });
        expect(onSetup).toHaveBeenCalledWith(defSetupOptions, seInstance);
        expect(onUse).toHaveBeenCalledWith(seInstance);
      });

      it('passes correct arguments to callback fns when un-using an extension', () => {
        seInstance = new Instance();
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
