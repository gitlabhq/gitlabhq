import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Draggable from 'vuedraggable';
import Vuex from 'vuex';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import getters from 'ee_else_ce/boards/stores/getters';
import BoardColumn from '~/boards/components/board_column.vue';
import BoardContent from '~/boards/components/board_content.vue';
import { mockLists, mockListsWithModel } from '../mock_data';

Vue.use(Vuex);

const actions = {
  moveList: jest.fn(),
};

describe('BoardContent', () => {
  let wrapper;
  window.gon = {};

  const defaultState = {
    isShowingEpicsSwimlanes: false,
    boardLists: mockLists,
    error: undefined,
  };

  const createStore = (state = defaultState) => {
    return new Vuex.Store({
      actions,
      getters,
      state,
    });
  };

  const createComponent = ({ state, props = {}, canAdminList = true } = {}) => {
    const store = createStore({
      ...defaultState,
      ...state,
    });
    wrapper = shallowMount(BoardContent, {
      propsData: {
        lists: mockListsWithModel,
        disabled: false,
        ...props,
      },
      provide: {
        canAdminList,
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
    expect(wrapper.findAllComponents(BoardColumn)).toHaveLength(mockListsWithModel.length);
  });

  it('does not display EpicsSwimlanes component', () => {
    expect(wrapper.find(EpicsSwimlanes).exists()).toBe(false);
    expect(wrapper.find(GlAlert).exists()).toBe(false);
  });

  describe('can admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: true });
    });

    it('renders draggable component', () => {
      expect(wrapper.find(Draggable).exists()).toBe(true);
    });
  });

  describe('can not admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: false });
    });

    it('does not render draggable component', () => {
      expect(wrapper.find(Draggable).exists()).toBe(false);
    });
  });
});
