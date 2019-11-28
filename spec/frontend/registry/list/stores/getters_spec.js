import * as getters from '~/registry/list/stores/getters';

describe('Getters Registry Store', () => {
  let state;

  beforeEach(() => {
    state = {
      isLoading: false,
      endpoint: '/root/empty-project/container_registry.json',
      isDeleteDisabled: false,
      repos: [
        {
          canDelete: true,
          destroyPath: 'bar',
          id: '134',
          isLoading: false,
          list: [],
          location: 'foo',
          name: 'gitlab-org/omnibus-gitlab/foo',
          tagsPath: 'foo',
        },
        {
          canDelete: true,
          destroyPath: 'bar',
          id: '123',
          isLoading: false,
          list: [],
          location: 'foo',
          name: 'gitlab-org/omnibus-gitlab',
          tagsPath: 'foo',
        },
      ],
    };
  });

  describe('isLoading', () => {
    it('should return the isLoading property', () => {
      expect(getters.isLoading(state)).toEqual(state.isLoading);
    });
  });

  describe('repos', () => {
    it('should return the repos', () => {
      expect(getters.repos(state)).toEqual(state.repos);
    });
  });
  describe('isDeleteDisabled', () => {
    it('should return isDeleteDisabled', () => {
      expect(getters.isDeleteDisabled(state)).toEqual(state.isDeleteDisabled);
    });
  });
});
