import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import BoardColumn from 'ee_else_ce/boards/components/board_column.vue';
import getters from 'ee_else_ce/boards/stores/getters';
import { mockListsWithModel } from '../mock_data';
import BoardContent from '~/boards/components/board_content.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('BoardContent', () => {
  let wrapper;

  const defaultState = {
    isShowingEpicsSwimlanes: false,
    boardLists: mockListsWithModel,
    error: undefined,
  };

  const createStore = (state = defaultState) => {
    return new Vuex.Store({
      getters,
      state,
    });
  };

  const createComponent = state => {
    const store = createStore({
      ...defaultState,
      ...state,
    });
    wrapper = shallowMount(BoardContent, {
      localVue,
      propsData: {
        lists: mockListsWithModel,
        canAdminList: true,
        disabled: false,
      },
      store,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a BoardColumn component per list', () => {
    expect(wrapper.findAll(BoardColumn)).toHaveLength(mockListsWithModel.length);
  });

  it('does not display EpicsSwimlanes component', () => {
    expect(wrapper.find(EpicsSwimlanes).exists()).toBe(false);
    expect(wrapper.find(GlAlert).exists()).toBe(false);
  });
});
