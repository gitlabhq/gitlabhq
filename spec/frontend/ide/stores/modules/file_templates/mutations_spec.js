import * as types from '~/ide/stores/modules/file_templates/mutation_types';
import mutations from '~/ide/stores/modules/file_templates/mutations';
import createState from '~/ide/stores/modules/file_templates/state';

const mockFileTemplates = [['MIT'], ['CC']];
const mockTemplateType = 'test';

describe('IDE file templates mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(`${types.REQUEST_TEMPLATE_TYPES}`, () => {
    it('sets loading to true', () => {
      state.isLoading = false;

      mutations[types.REQUEST_TEMPLATE_TYPES](state);

      expect(state.isLoading).toBe(true);
    });

    it('sets templates to an empty array', () => {
      state.templates = mockFileTemplates;

      mutations[types.REQUEST_TEMPLATE_TYPES](state);

      expect(state.templates).toEqual([]);
    });
  });

  describe(`${types.RECEIVE_TEMPLATE_TYPES_ERROR}`, () => {
    it('sets isLoading', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_TEMPLATE_TYPES_ERROR](state);

      expect(state.isLoading).toBe(false);
    });
  });

  describe(`${types.RECEIVE_TEMPLATE_TYPES_SUCCESS}`, () => {
    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_TEMPLATE_TYPES_SUCCESS](state, mockFileTemplates);

      expect(state.isLoading).toBe(false);
    });

    it('sets templates to payload', () => {
      state.templates = ['test'];

      mutations[types.RECEIVE_TEMPLATE_TYPES_SUCCESS](state, mockFileTemplates);

      expect(state.templates).toEqual(mockFileTemplates);
    });
  });

  describe(`${types.SET_SELECTED_TEMPLATE_TYPE}`, () => {
    it('sets templates type to selected type', () => {
      state.selectedTemplateType = '';

      mutations[types.SET_SELECTED_TEMPLATE_TYPE](state, mockTemplateType);

      expect(state.selectedTemplateType).toBe(mockTemplateType);
    });

    it('sets templates to empty array', () => {
      state.templates = mockFileTemplates;

      mutations[types.SET_SELECTED_TEMPLATE_TYPE](state, mockTemplateType);

      expect(state.templates).toEqual([]);
    });
  });

  describe(`${types.SET_UPDATE_SUCCESS}`, () => {
    it('sets updateSuccess', () => {
      state.updateSuccess = false;

      mutations[types.SET_UPDATE_SUCCESS](state, true);

      expect(state.updateSuccess).toBe(true);
    });
  });
});
