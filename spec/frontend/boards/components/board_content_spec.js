import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Draggable from 'vuedraggable';
import Vuex from 'vuex';

import eventHub from '~/boards/eventhub';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import getters from 'ee_else_ce/boards/stores/getters';
import BoardColumn from '~/boards/components/board_column.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { mockLists, mockListsById } from '../mock_data';

Vue.use(Vuex);

const actions = {
  moveList: jest.fn(),
};

describe('BoardContent', () => {
  let wrapper;

  const defaultState = {
    isShowingEpicsSwimlanes: false,
    boardLists: mockLists,
    error: undefined,
    issuableType: 'issue',
  };

  const createStore = (state = defaultState) => {
    return new Vuex.Store({
      actions,
      getters,
      state,
    });
  };

  const createComponent = ({
    state,
    props = {},
    canAdminList = true,
    isApolloBoard = false,
    issuableType = 'issue',
    isIssueBoard = true,
    isEpicBoard = false,
  } = {}) => {
    const store = createStore({
      ...defaultState,
      ...state,
    });
    wrapper = shallowMount(BoardContent, {
      propsData: {
        boardId: 'gid://gitlab/Board/1',
        filterParams: {},
        isSwimlanesOn: false,
        boardListsApollo: mockListsById,
        ...props,
      },
      provide: {
        canAdminList,
        issuableType,
        isIssueBoard,
        isEpicBoard,
        isGroupBoard: true,
        disabled: false,
        isApolloBoard,
      },
      store,
      stubs: {
        BoardContentSidebar: stubComponent(BoardContentSidebar, {
          template: '<div></div>',
        }),
      },
    });
  };

  beforeAll(() => {
    global.ResizeObserver = class MockResizeObserver {
      constructor(callback) {
        this.callback = callback;

        this.entries = [];
      }

      observe(entry) {
        this.entries.push(entry);
      }

      disconnect() {
        this.entries = [];
        this.callback = null;
      }

      trigger() {
        this.callback(this.entries);
      }
    };
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a BoardColumn component per list', () => {
      expect(wrapper.findAllComponents(BoardColumn)).toHaveLength(mockLists.length);
    });

    it('renders BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(true);
    });

    it('does not display EpicsSwimlanes component', () => {
      expect(wrapper.findComponent(EpicsSwimlanes).exists()).toBe(false);
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('on small screens, sets board container height to full height', async () => {
      window.innerHeight = 1000;
      window.innerWidth = 767;
      jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: 100 });

      wrapper.vm.resizeObserver.trigger();

      await nextTick();

      const style = wrapper.findComponent({ ref: 'list' }).attributes('style');

      expect(style).toBe('height: 1000px;');
    });

    it('on large screens, sets board container height fill area below filters', async () => {
      window.innerHeight = 1000;
      window.innerWidth = 768;
      jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: 100 });

      wrapper.vm.resizeObserver.trigger();

      await nextTick();

      const style = wrapper.findComponent({ ref: 'list' }).attributes('style');

      expect(style).toBe('height: 900px;');
    });

    it('sets delay and delayOnTouchOnly attributes on board list', () => {
      const listEl = wrapper.findComponent({ ref: 'list' });

      expect(listEl.attributes('delay')).toBe('100');
      expect(listEl.attributes('delayontouchonly')).toBe('true');
    });
  });

  describe('when issuableType is not issue', () => {
    beforeEach(() => {
      createComponent({ issuableType: 'foo', isIssueBoard: false });
    });

    it('does not render BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(false);
    });
  });

  describe('can admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: true });
    });

    it('renders draggable component', () => {
      expect(wrapper.findComponent(Draggable).exists()).toBe(true);
    });
  });

  describe('can not admin list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: false });
    });

    it('does not render draggable component', () => {
      expect(wrapper.findComponent(Draggable).exists()).toBe(false);
    });
  });

  describe('when Apollo boards FF is on', () => {
    beforeEach(async () => {
      createComponent({ isApolloBoard: true });
      await waitForPromises();
    });

    it('renders a BoardColumn component per list', () => {
      expect(wrapper.findAllComponents(BoardColumn)).toHaveLength(mockLists.length);
    });

    it('renders BoardContentSidebar', () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(true);
    });

    it('refetches lists when updateBoard event is received', async () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      createComponent({ isApolloBoard: true });
      await waitForPromises();

      expect(eventHub.$on).toHaveBeenCalledWith('updateBoard', wrapper.vm.refetchLists);
    });
  });
});
