import Vuex from 'vuex';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import { GlDeprecatedButton } from '@gitlab/ui';
import { AWS_ACCESS_KEY_ID } from '~/ci_variable_list/constants';
import CiVariableModal from '~/ci_variable_list/components/ci_variable_modal.vue';
import CiKeyField from '~/ci_variable_list/components/ci_key_field.vue';
import { awsTokens } from '~/ci_variable_list/components/ci_variable_autocomplete_tokens';
import createStore from '~/ci_variable_list/store';
import mockData from '../services/mock_data';
import ModalStub from '../stubs';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ci variable modal', () => {
  let wrapper;
  let store;

  const createComponent = (method, options = {}) => {
    store = createStore();
    wrapper = method(CiVariableModal, {
      attachToDocument: true,
      provide: { glFeatures: { ciKeyAutocomplete: true } },
      stubs: {
        GlModal: ModalStub,
      },
      localVue,
      store,
      ...options,
    });
  };

  const findModal = () => wrapper.find(ModalStub);
  const addOrUpdateButton = index =>
    findModal()
      .findAll(GlDeprecatedButton)
      .at(index);
  const deleteVariableButton = () =>
    findModal()
      .findAll(GlDeprecatedButton)
      .at(1);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Feature flag', () => {
    describe('when off', () => {
      beforeEach(() => {
        createComponent(shallowMount, { provide: { glFeatures: { ciKeyAutocomplete: false } } });
      });

      it('does not render the autocomplete dropdown', () => {
        expect(wrapper.contains(CiKeyField)).toBe(false);
      });
    });

    describe('when on', () => {
      beforeEach(() => {
        createComponent(shallowMount);
      });
      it('renders the autocomplete dropdown', () => {
        expect(wrapper.find(CiKeyField).exists()).toBe(true);
      });
    });
  });

  describe('Basic interactions', () => {
    beforeEach(() => {
      createComponent(shallowMount);
    });

    it('button is disabled when no key/value pair are present', () => {
      expect(addOrUpdateButton(1).attributes('disabled')).toBeTruthy();
    });
  });

  describe('Adding a new variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      createComponent(shallowMount);
      jest.spyOn(store, 'dispatch').mockImplementation();
      store.state.variable = variable;
    });

    it('button is enabled when key/value pair are present', () => {
      expect(addOrUpdateButton(1).attributes('disabled')).toBeFalsy();
    });

    it('Add variable button dispatches addVariable action', () => {
      addOrUpdateButton(1).vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith('addVariable');
    });

    it('Clears the modal state once modal is hidden', () => {
      findModal().vm.$emit('hidden');
      expect(store.dispatch).toHaveBeenCalledWith('clearModal');
    });

    it('should dispatch setVariableProtected when admin settings are configured to protect variables', () => {
      store.state.isProtectedByDefault = true;
      findModal().vm.$emit('shown');

      expect(store.dispatch).toHaveBeenCalledWith('setVariableProtected');
    });
  });

  describe('Editing a variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      createComponent(shallowMount);
      jest.spyOn(store, 'dispatch').mockImplementation();
      store.state.variableBeingEdited = variable;
    });

    it('button text is Update variable when updating', () => {
      expect(addOrUpdateButton(2).text()).toBe('Update variable');
    });

    it('Update variable button dispatches updateVariable with correct variable', () => {
      addOrUpdateButton(2).vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith(
        'updateVariable',
        store.state.variableBeingEdited,
      );
    });

    it('Resets the editing state once modal is hidden', () => {
      findModal().vm.$emit('hidden');
      expect(store.dispatch).toHaveBeenCalledWith('resetEditing');
    });

    it('dispatches deleteVariable with correct variable to delete', () => {
      deleteVariableButton().vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith('deleteVariable', mockData.mockVariables[0]);
    });
  });

  describe('Validations', () => {
    const maskError = 'This variable can not be masked.';

    describe('when the key state is invalid', () => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const invalidKeyVariable = {
          ...variable,
          key: AWS_ACCESS_KEY_ID,
          value: 'AKIAIOSFODNN7EXAMPLEjdhy',
          secret_value: 'AKIAIOSFODNN7EXAMPLEjdhy',
        };
        createComponent(mount);
        store.state.variable = invalidKeyVariable;
      });

      it('disables the submit button', () => {
        expect(addOrUpdateButton(1).attributes('disabled')).toBeTruthy();
      });

      it('shows the correct error text', () => {
        const errorText = awsTokens[AWS_ACCESS_KEY_ID].invalidMessage;
        expect(findModal().text()).toContain(errorText);
      });
    });

    describe('when the mask state is invalid', () => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const invalidMaskVariable = {
          ...variable,
          key: 'qs',
          value: 'd:;',
          secret_value: 'd:;',
          masked: true,
        };
        createComponent(mount);
        store.state.variable = invalidMaskVariable;
      });

      it('disables the submit button', () => {
        expect(addOrUpdateButton(1).attributes('disabled')).toBeTruthy();
      });

      it('shows the correct error text', () => {
        expect(findModal().text()).toContain(maskError);
      });
    });

    describe('when the mask and key states are invalid', () => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const invalidMaskandKeyVariable = {
          ...variable,
          key: AWS_ACCESS_KEY_ID,
          value: 'AKIAIOSFODNN7EXAMPLEjdhyd:;',
          secret_value: 'AKIAIOSFODNN7EXAMPLEjdhyd:;',
          masked: true,
        };
        createComponent(mount);
        store.state.variable = invalidMaskandKeyVariable;
      });

      it('disables the submit button', () => {
        expect(addOrUpdateButton(1).attributes('disabled')).toBeTruthy();
      });

      it('shows the correct error text', () => {
        const errorText = awsTokens[AWS_ACCESS_KEY_ID].invalidMessage;
        expect(findModal().text()).toContain(maskError);
        expect(findModal().text()).toContain(errorText);
      });
    });

    describe('when both states are valid', () => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const validMaskandKeyVariable = {
          ...variable,
          key: AWS_ACCESS_KEY_ID,
          value: 'AKIAIOSFODNN7EXAMPLE',
          secret_value: 'AKIAIOSFODNN7EXAMPLE',
          masked: true,
        };
        createComponent(mount);
        store.state.variable = validMaskandKeyVariable;
        store.state.maskableRegex = /^[a-zA-Z0-9_+=/@:-]{8,}$/;
      });

      it('does not disable the submit button', () => {
        expect(addOrUpdateButton(1).attributes('disabled')).toBeFalsy();
      });

      it('shows no error text', () => {
        const errorText = awsTokens[AWS_ACCESS_KEY_ID].invalidMessage;
        expect(findModal().text()).not.toContain(maskError);
        expect(findModal().text()).not.toContain(errorText);
      });
    });
  });
});
