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
        codeNavUrl: 'https://test.com/builds/1005',
        definitionPathPrefix: 'https://test.com/blob/master',
      });

      expect(state.codeNavUrl).toBe('https://test.com/builds/1005');
      expect(state.definitionPathPrefix).toBe('https://test.com/blob/master');
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
