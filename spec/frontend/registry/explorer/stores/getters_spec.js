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
});
