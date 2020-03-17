import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import CiVariableModal from '~/ci_variable_list/components/ci_variable_modal.vue';
import createStore from '~/ci_variable_list/store';
import mockData from '../services/mock_data';
import ModalStub from '../stubs';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ci variable modal', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore();
    wrapper = shallowMount(CiVariableModal, {
      stubs: {
        GlModal: ModalStub,
      },
      localVue,
      store,
    });
  };

  const findModal = () => wrapper.find(ModalStub);
  const addOrUpdateButton = index =>
    findModal()
      .findAll(GlButton)
      .at(index);
  const deleteVariableButton = () =>
    findModal()
      .findAll(GlButton)
      .at(1);

  beforeEach(() => {
    createComponent();
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('button is disabled when no key/value pair are present', () => {
    expect(addOrUpdateButton(1).attributes('disabled')).toBeTruthy();
  });

  describe('Adding a new variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
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
  });

  describe('Editing a variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
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
});
