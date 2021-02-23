import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumn from '~/boards/components/board_add_new_column.vue';
import defaultState from '~/boards/stores/state';
import { mockLabelList } from '../mock_data';

Vue.use(Vuex);

describe('Board card layout', () => {
  let wrapper;
  let shouldUseGraphQL;

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
    selectedLabelId,
    labels = [],
    getListByLabelId = jest.fn(),
    actions = {},
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(BoardAddNewColumn, {
        stubs: {
          GlFormGroup: true,
        },
        data() {
          return {
            selectedLabelId,
          };
        },
        store: createStore({
          actions: {
            fetchLabels: jest.fn(),
            setAddColumnFormVisibility: jest.fn(),
            ...actions,
          },
          getters: {
            shouldUseGraphQL: () => shouldUseGraphQL,
            getListByLabelId: () => getListByLabelId,
          },
          state: {
            labels,
            labelsLoading: false,
          },
        }),
        provide: {
          scopedLabelsAvailable: true,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const formTitle = () => wrapper.findByTestId('board-add-column-form-title').text();
  const findSearchInput = () => wrapper.find(GlSearchBoxByType);
  const cancelButton = () => wrapper.findByTestId('cancelAddNewColumn');
  const submitButton = () => wrapper.findByTestId('addNewColumnButton');

  beforeEach(() => {
    shouldUseGraphQL = true;
  });

  it('shows form title & search input', () => {
    mountComponent();

    expect(formTitle()).toEqual(BoardAddNewColumn.i18n.newLabelList);
    expect(findSearchInput().exists()).toBe(true);
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
    it('is disabled if no item is selected', () => {
      mountComponent();

      expect(submitButton().props('disabled')).toBe(true);
    });

    it('adds a new list on click', async () => {
      const labelId = mockLabelList.label.id;
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        labels: [mockLabelList.label],
        selectedLabelId: labelId,
        actions: {
          createList,
          highlightList,
        },
      });

      await nextTick();

      submitButton().vm.$emit('click');

      expect(highlightList).not.toHaveBeenCalled();
      expect(createList).toHaveBeenCalledWith(expect.anything(), { labelId });
    });

    it('highlights existing list if trying to re-add', async () => {
      const getListByLabelId = jest.fn().mockReturnValue(mockLabelList);
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        labels: [mockLabelList.label],
        selectedLabelId: mockLabelList.label.id,
        getListByLabelId,
        actions: {
          createList,
          highlightList,
        },
      });

      await nextTick();

      submitButton().vm.$emit('click');

      expect(highlightList).toHaveBeenCalledWith(expect.anything(), mockLabelList.id);
      expect(createList).not.toHaveBeenCalled();
    });
  });
});
