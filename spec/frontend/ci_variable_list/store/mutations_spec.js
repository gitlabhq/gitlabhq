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
    it('should set variable that is being edited', () => {
      const variableBeingEdited = {
        environment_scope: '*',
        id: 63,
        key: 'test_var',
        masked: false,
        protected: false,
        value: 'test_val',
        variable_type: 'env_var',
      };

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
        environment_scope: 'All environments',
      };

      mutations[types.CLEAR_MODAL](stateCopy);

      expect(stateCopy.variable).toEqual(modalState);
    });
  });
});
