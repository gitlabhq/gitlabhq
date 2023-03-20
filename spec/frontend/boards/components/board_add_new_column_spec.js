import { GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumn from '~/boards/components/board_add_new_column.vue';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import defaultState from '~/boards/stores/state';
import { mockLabelList } from '../mock_data';

Vue.use(Vuex);

describe('Board card layout', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const selectLabel = (id) => {
    findDropdown().vm.$emit('select', id);
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
    wrapper = shallowMountExtended(BoardAddNewColumn, {
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
          getListByLabelId: () => getListByLabelId,
        },
        state: {
          labels,
          labelsLoading: false,
        },
      }),
      provide: {
        scopedLabelsAvailable: true,
        isEpicBoard: false,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });

    // trigger change event
    if (selectedId) {
      selectLabel(selectedId);
    }
  };

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
