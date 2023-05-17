import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import defaultState from '~/boards/stores/state';
import { mockLabelList } from '../mock_data';

Vue.use(Vuex);

describe('BoardAddNewColumnForm', () => {
  let wrapper;

  const createStore = ({ actions = {}, getters = {}, state = {} } = {}) => {
    return new Vuex.Store({
      state: {
        ...defaultState,
        ...state,
      },
      actions,
      getters,
    });
  };

  const mountComponent = ({ searchLabel = '', selectedIdValid = true, actions, slots } = {}) => {
    wrapper = shallowMountExtended(BoardAddNewColumnForm, {
      propsData: {
        searchLabel,
        selectedIdValid,
      },
      slots,
      store: createStore({
        actions: {
          setAddColumnFormVisibility: jest.fn(),
          ...actions,
        },
      }),
    });
  };

  const formTitle = () => wrapper.findByTestId('board-add-column-form-title').text();
  const cancelButton = () => wrapper.findByTestId('cancelAddNewColumn');
  const submitButton = () => wrapper.findByTestId('addNewColumnButton');

  it('shows form title', () => {
    mountComponent();

    expect(formTitle()).toEqual(BoardAddNewColumnForm.i18n.newList);
  });

  it('clicking cancel hides the form', () => {
    const setAddColumnFormVisibility = jest.fn();
    mountComponent({
      actions: {
        setAddColumnFormVisibility,
      },
    });

    cancelButton().vm.$emit('click');

    expect(setAddColumnFormVisibility).toHaveBeenCalledWith(expect.anything(), false);
  });

  describe('Add list button', () => {
    it('is enabled by default', () => {
      mountComponent();

      expect(submitButton().props('disabled')).toBe(false);
    });

    it('emits add-list event on click when an ID is selected', () => {
      mountComponent({
        selectedId: mockLabelList.label.id,
      });

      submitButton().vm.$emit('click');

      expect(wrapper.emitted('add-list')).toEqual([[]]);
    });
  });
});
