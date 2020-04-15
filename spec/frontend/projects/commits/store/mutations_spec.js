import * as types from '~/projects/commits/store/mutation_types';
import mutations from '~/projects/commits/store/mutations';
import createState from '~/projects/commits/store/state';

describe('Project commits mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  afterEach(() => {
    state = null;
  });

  describe(`${types.SET_INITIAL_DATA}`, () => {
    it('sets initial data', () => {
      state.commitsPath = null;
      state.projectId = null;
      state.commitsAuthors = [];

      const data = {
        commitsPath: 'some/path',
        projectId: '8',
      };

      mutations[types.SET_INITIAL_DATA](state, data);

      expect(state).toEqual(expect.objectContaining(data));
    });
  });

  describe(`${types.COMMITS_AUTHORS}`, () => {
    it('sets commitsAuthors', () => {
      const authors = [{ id: 1 }, { id: 2 }];
      state.commitsAuthors = [];

      mutations[types.COMMITS_AUTHORS](state, authors);

      expect(state.commitsAuthors).toEqual(authors);
    });
  });
});
