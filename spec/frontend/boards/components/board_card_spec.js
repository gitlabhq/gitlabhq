import { GlLabel } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import { inactiveId } from '~/boards/constants';
import { mockLabelList, mockIssue, DEFAULT_COLOR } from '../mock_data';

describe('Board card', () => {
  let wrapper;
  let store;
  let mockActions;

  Vue.use(Vuex);
  Vue.use(VueApollo);

  const mockSetActiveBoardItemResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setActiveBoardItem: mockSetActiveBoardItemResolver,
    },
  });

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
    });
  };

  // this particular mount component needs to be used after the root beforeEach because it depends on list being initialized
  const mountComponent = ({
    propsData = {},
    provide = {},
    stubs = { BoardCardInner },
    item = mockIssue,
  } = {}) => {
    wrapper = shallowMountExtended(BoardCard, {
      apolloProvider: mockApollo,
      stubs: {
        ...stubs,
        BoardCardInner,
      },
      store,
      propsData: {
        list: mockLabelList,
        item,
        index: 0,
        ...propsData,
      },
      provide: {
        groupId: null,
        rootPath: '/',
        scopedLabelsAvailable: false,
        isIssueBoard: true,
        isEpicBoard: false,
        issuableType: 'issue',
        isGroupBoard: true,
        disabled: false,
        isApolloBoard: false,
        ...provide,
      },
    });
  };

  const selectCard = async () => {
    wrapper.trigger('click');
    await nextTick();
  };

  const multiSelectCard = async () => {
    wrapper.trigger('click', { ctrlKey: true });
    await nextTick();
  };

  beforeEach(() => {
    window.gon = { features: {} };
  });

  afterEach(() => {
    store = null;
  });

  describe('when GlLabel is clicked in BoardCardInner', () => {
    it('doesnt call toggleBoardItem', () => {
      createStore({ initialState: { isShowingLabels: true } });
      mountComponent();

      wrapper.findComponent(GlLabel).trigger('mouseup');

      expect(mockActions.toggleBoardItem).toHaveBeenCalledTimes(0);
    });
  });

  it('should not highlight the card by default', () => {
    createStore();
    mountComponent();

    expect(wrapper.classes()).not.toContain('is-active');
    expect(wrapper.classes()).not.toContain('multi-select');
  });

  it('should highlight the card with a correct style when selected', () => {
    createStore({
      initialState: {
        activeId: mockIssue.id,
      },
    });
    mountComponent();

    expect(wrapper.classes()).toContain('is-active');
    expect(wrapper.classes()).not.toContain('multi-select');
  });

  it('should highlight the card with a correct style when multi-selected', () => {
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
      expect(wrapper.classes()).not.toContain('gl-cursor-grab');
    });
  });

  describe('when card is not loading', () => {
    it('user can drag', () => {
      createStore();
      mountComponent();

      expect(wrapper.classes()).not.toContain('is-disabled');
      expect(wrapper.classes()).toContain('gl-cursor-grab');
    });
  });

  describe('when Epic colors are enabled', () => {
    it('applies the correct color', () => {
      window.gon.features = { epicColorHighlight: true };
      createStore();
      mountComponent({
        item: {
          ...mockIssue,
          color: DEFAULT_COLOR,
        },
      });

      expect(wrapper.classes()).toEqual(
        expect.arrayContaining(['gl-pl-4', 'gl-border-l-solid', 'gl-border-4']),
      );
      expect(wrapper.attributes('style')).toContain(`border-color: ${DEFAULT_COLOR}`);
    });
  });

  describe('when Epic colors are not enabled', () => {
    it('applies the correct color', () => {
      window.gon.features = { epicColorHighlight: false };
      createStore();
      mountComponent({
        item: {
          ...mockIssue,
          color: DEFAULT_COLOR,
        },
      });

      expect(wrapper.classes()).not.toEqual(
        expect.arrayContaining(['gl-pl-4', 'gl-border-l-solid', 'gl-border-4']),
      );
      expect(wrapper.attributes('style')).toBeUndefined();
    });
  });

  describe('Apollo boards', () => {
    beforeEach(async () => {
      createStore();
      mountComponent({ provide: { isApolloBoard: true } });
      await nextTick();
    });

    it('set active board item on client when clicking on card', async () => {
      await selectCard();

      expect(mockSetActiveBoardItemResolver).toHaveBeenCalledWith(
        {},
        {
          boardItem: mockIssue,
        },
        expect.anything(),
        expect.anything(),
      );
    });
  });
});
