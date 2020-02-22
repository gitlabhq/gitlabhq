import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import CiVariableModal from '~/ci_variable_list/components/ci_variable_modal.vue';
import createStore from '~/ci_variable_list/store';
import mockData from '../services/mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ci variable modal', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore();
    wrapper = shallowMount(CiVariableModal, {
      localVue,
      store,
    });
  };

  const findModal = () => wrapper.find(GlModal);

  beforeEach(() => {
    createComponent();
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('button is disabled when no key/value pair are present', () => {
    expect(findModal().props('actionPrimary').attributes.disabled).toBeTruthy();
  });

  it('masked checkbox is disabled when value does not meet regex requirements', () => {
    expect(wrapper.find({ ref: 'masked-ci-variable' }).attributes('disabled')).toBeTruthy();
  });

  describe('Adding a new variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      store.state.variable = variable;
    });

    it('button is enabled when key/value pair are present', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBeFalsy();
    });

    it('masked checkbox is enabled when value meets regex requirements', () => {
      store.state.maskableRegex = '^[a-zA-Z0-9_+=/@:-]{8,}$';
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find({ ref: 'masked-ci-variable' }).attributes('disabled')).toBeFalsy();
      });
    });

    it('Add variable button dispatches addVariable action', () => {
      findModal().vm.$emit('ok');
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
      expect(wrapper.vm.modalActionText).toBe('Update Variable');
    });

    it('Update variable button dispatches updateVariable with correct variable', () => {
      findModal().vm.$emit('ok');
      expect(store.dispatch).toHaveBeenCalledWith(
        'updateVariable',
        store.state.variableBeingEdited,
      );
    });

    it('Resets the editing state once modal is hidden', () => {
      findModal().vm.$emit('hidden');
      expect(store.dispatch).toHaveBeenCalledWith('resetEditing');
    });
  });
});
