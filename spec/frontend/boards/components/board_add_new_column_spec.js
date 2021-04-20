import { GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumn from '~/boards/components/board_add_new_column.vue';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import defaultState from '~/boards/stores/state';
import { mockLabelList } from '../mock_data';

Vue.use(Vuex);

describe('Board card layout', () => {
  let wrapper;

  const selectLabel = (id) => {
    wrapper.findComponent(GlFormRadioGroup).vm.$emit('change', id);
  };

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

  const mountComponent = ({
    selectedId,
    labels = [],
    getListByLabelId = jest.fn(),
    actions = {},
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(BoardAddNewColumn, {
        data() {
          return {
            selectedId,
          };
        },
        store: createStore({
          actions: {
            fetchLabels: jest.fn(),
            setAddColumnFormVisibility: jest.fn(),
            ...actions,
          },
          getters: {
            shouldUseGraphQL: () => true,
            getListByLabelId: () => getListByLabelId,
          },
          state: {
            labels,
            labelsLoading: false,
            isEpicBoard: false,
          },
        }),
        provide: {
          scopedLabelsAvailable: true,
        },
      }),
    );

    // trigger change event
    if (selectedId) {
      selectLabel(selectedId);
    }
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Add list button', () => {
    it('calls addList', async () => {
      const getListByLabelId = jest.fn().mockReturnValue(null);
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        labels: [mockLabelList.label],
        selectedId: mockLabelList.label.id,
        getListByLabelId,
        actions: {
          createList,
          highlightList,
        },
      });

      wrapper.findComponent(BoardAddNewColumnForm).vm.$emit('add-list');

      await nextTick();

      expect(highlightList).not.toHaveBeenCalled();
      expect(createList).toHaveBeenCalledWith(expect.anything(), {
        labelId: mockLabelList.label.id,
      });
    });

    it('highlights existing list if trying to re-add', async () => {
      const getListByLabelId = jest.fn().mockReturnValue(mockLabelList);
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        labels: [mockLabelList.label],
        selectedId: mockLabelList.label.id,
        getListByLabelId,
        actions: {
          createList,
          highlightList,
        },
      });

      wrapper.findComponent(BoardAddNewColumnForm).vm.$emit('add-list');

      await nextTick();

      expect(highlightList).toHaveBeenCalledWith(expect.anything(), mockLabelList.id);
      expect(createList).not.toHaveBeenCalled();
    });
  });
});
