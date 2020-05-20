import state from '~/ci_variable_list/store/state';
import mutations from '~/ci_variable_list/store/mutations';
import * as types from '~/ci_variable_list/store/mutation_types';

describe('CI variable list mutations', () => {
  let stateCopy;
  const variableBeingEdited = {
    environment_scope: '*',
    id: 63,
    key: 'test_var',
    masked: false,
    protected: false,
    value: 'test_val',
    variable_type: 'env_var',
  };

  beforeEach(() => {
    stateCopy = state();
  });

  describe('TOGGLE_VALUES', () => {
    it('should toggle state', () => {
      const valuesHidden = false;

      mutations[types.TOGGLE_VALUES](stateCopy, valuesHidden);

      expect(stateCopy.valuesHidden).toEqual(valuesHidden);
    });
  });

  describe('VARIABLE_BEING_EDITED', () => {
    it('should set variable that is being edited', () => {
      mutations[types.VARIABLE_BEING_EDITED](stateCopy, variableBeingEdited);

      expect(stateCopy.variableBeingEdited).toEqual(variableBeingEdited);
    });
  });

  describe('RESET_EDITING', () => {
    it('should reset variableBeingEdited to null', () => {
      mutations[types.RESET_EDITING](stateCopy);

      expect(stateCopy.variableBeingEdited).toEqual(null);
    });
  });

  describe('CLEAR_MODAL', () => {
    it('should clear modal state ', () => {
      const modalState = {
        variable_type: 'Variable',
        key: '',
        secret_value: '',
        protected: false,
        masked: false,
        environment_scope: 'All (default)',
      };

      mutations[types.CLEAR_MODAL](stateCopy);

      expect(stateCopy.variable).toEqual(modalState);
    });
  });

  describe('RECEIVE_ENVIRONMENTS_SUCCESS', () => {
    it('should set environments', () => {
      const environments = ['env1', 'env2'];

      mutations[types.RECEIVE_ENVIRONMENTS_SUCCESS](stateCopy, environments);

      expect(stateCopy.environments).toEqual(['All (default)', 'env1', 'env2']);
    });
  });

  describe('SET_ENVIRONMENT_SCOPE', () => {
    const environment = 'production';

    it('should set scope to variable being updated if updating variable', () => {
      stateCopy.variableBeingEdited = variableBeingEdited;

      mutations[types.SET_ENVIRONMENT_SCOPE](stateCopy, environment);

      expect(stateCopy.variableBeingEdited.environment_scope).toBe('production');
    });

    it('should set scope to variable if adding new variable', () => {
      mutations[types.SET_ENVIRONMENT_SCOPE](stateCopy, environment);

      expect(stateCopy.variable.environment_scope).toBe('production');
    });
  });

  describe('ADD_WILD_CARD_SCOPE', () => {
    it('should add wild card scope to enviroments array and sort', () => {
      stateCopy.environments = ['dev', 'staging'];
      mutations[types.ADD_WILD_CARD_SCOPE](stateCopy, 'production');

      expect(stateCopy.environments).toEqual(['dev', 'production', 'staging']);
    });
  });

  describe('SET_VARIABLE_PROTECTED', () => {
    it('should set protected value to true', () => {
      mutations[types.SET_VARIABLE_PROTECTED](stateCopy);

      expect(stateCopy.variable.protected).toBe(true);
    });
  });
});
