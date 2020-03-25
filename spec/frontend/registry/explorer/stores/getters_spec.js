import * as getters from '~/registry/explorer/stores/getters';

describe('Getters RegistryExplorer  store', () => {
  let state;
  const tags = ['foo', 'bar'];

  describe('tags', () => {
    describe('when isLoading is false', () => {
      beforeEach(() => {
        state = {
          tags,
          isLoading: false,
        };
      });

      it('returns tags', () => {
        expect(getters.tags(state)).toEqual(state.tags);
      });
    });

    describe('when isLoading is true', () => {
      beforeEach(() => {
        state = {
          tags,
          isLoading: true,
        };
      });

      it('returns empty array', () => {
        expect(getters.tags(state)).toEqual([]);
      });
    });
  });

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
