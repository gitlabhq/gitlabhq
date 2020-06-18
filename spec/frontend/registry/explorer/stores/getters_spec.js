import * as getters from '~/registry/explorer/stores/getters';

describe('Getters RegistryExplorer  store', () => {
  let state;

  describe.each`
    getter                  | prefix               | configParameter              | suffix
    ${'dockerBuildCommand'} | ${'docker build -t'} | ${'repositoryUrl'}           | ${'.'}
    ${'dockerPushCommand'}  | ${'docker push'}     | ${'repositoryUrl'}           | ${null}
    ${'dockerLoginCommand'} | ${'docker login'}    | ${'registryHostUrlWithPort'} | ${null}
  `('$getter', ({ getter, prefix, configParameter, suffix }) => {
    beforeEach(() => {
      state = {
        config: { repositoryUrl: 'foo', registryHostUrlWithPort: 'bar' },
      };
    });

    it(`returns ${prefix} concatenated with ${configParameter} and optionally suffixed with ${suffix}`, () => {
      const expectedPieces = [prefix, state.config[configParameter], suffix].filter(p => p);
      expect(getters[getter](state)).toBe(expectedPieces.join(' '));
    });
  });

  describe('showGarbageCollection', () => {
    it.each`
      result   | showGarbageCollectionTip | isAdmin
      ${true}  | ${true}                  | ${true}
      ${false} | ${true}                  | ${false}
      ${false} | ${false}                 | ${true}
    `(
      'return $result when showGarbageCollectionTip $showGarbageCollectionTip and isAdmin is $isAdmin',
      ({ result, showGarbageCollectionTip, isAdmin }) => {
        state = {
          config: { isAdmin },
          showGarbageCollectionTip,
        };
        expect(getters.showGarbageCollection(state)).toBe(result);
      },
    );
  });
});
