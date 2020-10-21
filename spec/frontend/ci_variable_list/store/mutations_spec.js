import state from '~/ci_variable_list/store/state';
import mutations from '~/ci_variable_list/store/mutations';
import * as types from '~/ci_variable_list/store/mutation_types';

describe('CI variable list mutations', () => {
  let stateCopy;

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
    it('should set the variable that is being edited', () => {
      mutations[types.VARIABLE_BEING_EDITED](stateCopy);

      expect(stateCopy.variableBeingEdited).toBe(true);
    });
  });

  describe('RESET_EDITING', () => {
    it('should reset variableBeingEdited to false', () => {
      mutations[types.RESET_EDITING](stateCopy);

      expect(stateCopy.variableBeingEdited).toBe(false);
    });
  });

  describe('CLEAR_MODAL', () => {
    it('should clear modal state ', () => {
      const modalState = {
        variable_type: 'Variable',
        key: '',
        secret_value: '',
        protected_variable: false,
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

    it('should set environment scope on variable', () => {
      mutations[types.SET_ENVIRONMENT_SCOPE](stateCopy, environment);

      expect(stateCopy.variable.environment_scope).toBe('production');
    });
  });

  describe('ADD_WILD_CARD_SCOPE', () => {
    it('should add wild card scope to environments array and sort', () => {
      stateCopy.environments = ['dev', 'staging'];
      mutations[types.ADD_WILD_CARD_SCOPE](stateCopy, 'production');

      expect(stateCopy.environments).toEqual(['dev', 'production', 'staging']);
    });
  });

  describe('SET_VARIABLE_PROTECTED', () => {
    it('should set protected value to true', () => {
      mutations[types.SET_VARIABLE_PROTECTED](stateCopy);

      expect(stateCopy.variable.protected_variable).toBe(true);
    });
  });

  describe('UPDATE_VARIABLE_KEY', () => {
    it('should update variable key value', () => {
      const key = 'new_var';
      mutations[types.UPDATE_VARIABLE_KEY](stateCopy, key);

      expect(stateCopy.variable.key).toBe(key);
    });
  });

  describe('UPDATE_VARIABLE_VALUE', () => {
    it('should update variable value', () => {
      const value = 'variable_value';
      mutations[types.UPDATE_VARIABLE_VALUE](stateCopy, value);

      expect(stateCopy.variable.secret_value).toBe(value);
    });
  });

  describe('UPDATE_VARIABLE_TYPE', () => {
    it('should update variable type value', () => {
      const type = 'File';
      mutations[types.UPDATE_VARIABLE_TYPE](stateCopy, type);

      expect(stateCopy.variable.variable_type).toBe(type);
    });
  });

  describe('UPDATE_VARIABLE_PROTECTED', () => {
    it('should update variable protected value', () => {
      const protectedValue = true;
      mutations[types.UPDATE_VARIABLE_PROTECTED](stateCopy, protectedValue);

      expect(stateCopy.variable.protected_variable).toBe(protectedValue);
    });
  });

  describe('UPDATE_VARIABLE_MASKED', () => {
    it('should update variable masked value', () => {
      const masked = true;
      mutations[types.UPDATE_VARIABLE_MASKED](stateCopy, masked);

      expect(stateCopy.variable.masked).toBe(masked);
    });
  });
});
