import mutations from '~/code_navigation/store/mutations';
import createState from '~/code_navigation/store/state';

let state;

describe('Code navigation mutations', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('SET_INITIAL_DATA', () => {
    it('sets initial data', () => {
      mutations.SET_INITIAL_DATA(state, {
        projectPath: 'test',
        commitId: '123',
        blobPath: 'index.js',
      });

      expect(state.projectPath).toBe('test');
      expect(state.commitId).toBe('123');
      expect(state.blobPath).toBe('index.js');
    });
  });

  describe('REQUEST_DATA', () => {
    it('sets loading true', () => {
      mutations.REQUEST_DATA(state);

      expect(state.loading).toBe(true);
    });
  });

  describe('REQUEST_DATA_SUCCESS', () => {
    it('sets loading false', () => {
      mutations.REQUEST_DATA_SUCCESS(state, ['test']);

      expect(state.loading).toBe(false);
    });

    it('sets data', () => {
      mutations.REQUEST_DATA_SUCCESS(state, ['test']);

      expect(state.data).toEqual(['test']);
    });
  });

  describe('REQUEST_DATA_ERROR', () => {
    it('sets loading false', () => {
      mutations.REQUEST_DATA_ERROR(state);

      expect(state.loading).toBe(false);
    });
  });

  describe('SET_CURRENT_DEFINITION', () => {
    it('sets current definition and position', () => {
      mutations.SET_CURRENT_DEFINITION(state, { definition: 'test', position: { x: 0 } });

      expect(state.currentDefinition).toBe('test');
      expect(state.currentDefinitionPosition).toEqual({ x: 0 });
    });
  });
});
