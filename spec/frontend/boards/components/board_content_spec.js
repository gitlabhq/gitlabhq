import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import BoardColumn from 'ee_else_ce/boards/components/board_column.vue';
import getters from 'ee_else_ce/boards/stores/getters';
import { mockListsWithModel } from '../mock_data';
import BoardContent from '~/boards/components/board_content.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const actions = {
  moveList: jest.fn(),
  showPromotionList: jest.fn(),
};

describe('BoardContent', () => {
  let wrapper;

  const defaultState = {
    isShowingEpicsSwimlanes: false,
    boardLists: mockListsWithModel,
    error: undefined,
  };

  const createStore = (state = defaultState) => {
    return new Vuex.Store({
      actions,
      getters,
      state,
    });
  };

  const createComponent = ({ state, props = {}, graphqlBoardListsEnabled = false } = {}) => {
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
        ...props,
      },
      provide: {
        glFeatures: { graphqlBoardLists: graphqlBoardListsEnabled },
      },
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a BoardColumn component per list', () => {
    createComponent();

    expect(wrapper.findAll(BoardColumn)).toHaveLength(mockListsWithModel.length);
  });

  it('does not display EpicsSwimlanes component', () => {
    createComponent();

    expect(wrapper.find(EpicsSwimlanes).exists()).toBe(false);
    expect(wrapper.find(GlAlert).exists()).toBe(false);
  });

  describe('graphqlBoardLists feature flag enabled', () => {
    describe('can admin list', () => {
      beforeEach(() => {
        createComponent({ graphqlBoardListsEnabled: true, props: { canAdminList: true } });
      });

      it('renders draggable component', () => {
        expect(wrapper.find(Draggable).exists()).toBe(true);
      });
    });

    describe('can not admin list', () => {
      beforeEach(() => {
        createComponent({ graphqlBoardListsEnabled: true, props: { canAdminList: false } });
      });

      it('renders draggable component', () => {
        expect(wrapper.find(Draggable).exists()).toBe(false);
      });
    });
  });

  describe('graphqlBoardLists feature flag disabled', () => {
    beforeEach(() => {
      createComponent({ graphqlBoardListsEnabled: false });
    });

    it('does not render draggable component', () => {
      expect(wrapper.find(Draggable).exists()).toBe(false);
    });
  });
});
