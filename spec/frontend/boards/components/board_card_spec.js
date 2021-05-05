import { GlLabel } from '@gitlab/ui';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';

import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import { inactiveId } from '~/boards/constants';
import { mockLabelList, mockIssue } from '../mock_data';

describe('Board card', () => {
  let wrapper;
  let store;
  let mockActions;

  const localVue = createLocalVue();
  localVue.use(Vuex);

  const createStore = ({ initialState = {} } = {}) => {
    mockActions = {
      toggleBoardItem: jest.fn(),
      toggleBoardItemMultiSelection: jest.fn(),
      performSearch: jest.fn(),
    };

    store = new Vuex.Store({
      state: {
        activeId: inactiveId,
        selectedBoardItems: [],
        ...initialState,
      },
      actions: mockActions,
      getters: {
        isEpicBoard: () => false,
      },
    });
  };

  // this particular mount component needs to be used after the root beforeEach because it depends on list being initialized
  const mountComponent = ({
    propsData = {},
    provide = {},
    mountFn = shallowMount,
    stubs = { BoardCardInner },
  } = {}) => {
    wrapper = mountFn(BoardCard, {
      localVue,
      stubs,
      store,
      propsData: {
        list: mockLabelList,
        item: mockIssue,
        disabled: false,
        index: 0,
        ...propsData,
      },
      provide: {
        groupId: null,
        rootPath: '/',
        scopedLabelsAvailable: false,
        ...provide,
      },
    });
  };

  const selectCard = async () => {
    wrapper.trigger('mouseup');
    await wrapper.vm.$nextTick();
  };

  const multiSelectCard = async () => {
    wrapper.trigger('mouseup', { ctrlKey: true });
    await wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  describe('when GlLabel is clicked in BoardCardInner', () => {
    it('doesnt call toggleBoardItem', () => {
      createStore({ initialState: { isShowingLabels: true } });
      mountComponent({ mountFn: mount, stubs: {} });

      wrapper.find(GlLabel).trigger('mouseup');

      expect(mockActions.toggleBoardItem).toHaveBeenCalledTimes(0);
    });
  });

  it('should not highlight the card by default', async () => {
    createStore();
    mountComponent();

    expect(wrapper.classes()).not.toContain('is-active');
    expect(wrapper.classes()).not.toContain('multi-select');
  });

  it('should highlight the card with a correct style when selected', async () => {
    createStore({
      initialState: {
        activeId: mockIssue.id,
      },
    });
    mountComponent();

    expect(wrapper.classes()).toContain('is-active');
    expect(wrapper.classes()).not.toContain('multi-select');
  });

  it('should highlight the card with a correct style when multi-selected', async () => {
    createStore({
      initialState: {
        activeId: inactiveId,
        selectedBoardItems: [mockIssue],
      },
    });
    mountComponent();

    expect(wrapper.classes()).toContain('multi-select');
    expect(wrapper.classes()).not.toContain('is-active');
  });

  describe('when mouseup event is called on the card', () => {
    beforeEach(() => {
      createStore();
      mountComponent();
    });

    describe('when not using multi-select', () => {
      it('should call vuex action "toggleBoardItem" with correct parameters', async () => {
        await selectCard();

        expect(mockActions.toggleBoardItem).toHaveBeenCalledTimes(1);
        expect(mockActions.toggleBoardItem).toHaveBeenCalledWith(expect.any(Object), {
          boardItem: mockIssue,
        });
      });
    });

    describe('when using multi-select', () => {
      it('should call vuex action "multiSelectBoardItem" with correct parameters', async () => {
        await multiSelectCard();

        expect(mockActions.toggleBoardItemMultiSelection).toHaveBeenCalledTimes(1);
        expect(mockActions.toggleBoardItemMultiSelection).toHaveBeenCalledWith(
          expect.any(Object),
          mockIssue,
        );
      });
    });
  });
});
