import { GlLabel } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import { inactiveId } from '~/boards/constants';
import { mockLabelList, mockIssue } from '../mock_data';

describe('Board card', () => {
  let wrapper;
  let store;
  let mockActions;

  Vue.use(Vuex);

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
    item = mockIssue,
  } = {}) => {
    wrapper = mountFn(BoardCard, {
      stubs,
      store,
      propsData: {
        list: mockLabelList,
        item,
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

  beforeEach(() => {
    window.gon = { features: {} };
  });

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
      beforeEach(() => {
        window.gon = { features: { boardMultiSelect: true } };
      });

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

  describe('when card is loading', () => {
    it('card is disabled and user cannot drag', () => {
      createStore();
      mountComponent({ item: { ...mockIssue, isLoading: true } });

      expect(wrapper.classes()).toContain('is-disabled');
      expect(wrapper.classes()).not.toContain('user-can-drag');
    });
  });

  describe('when card is not loading', () => {
    it('user can drag', () => {
      createStore();
      mountComponent();

      expect(wrapper.classes()).not.toContain('is-disabled');
      expect(wrapper.classes()).toContain('user-can-drag');
    });
  });
});
