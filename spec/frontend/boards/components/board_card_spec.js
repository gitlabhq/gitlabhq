import { GlLabel } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import selectedBoardItemsQuery from '~/boards/graphql/client/selected_board_items.query.graphql';
import activeBoardItemQuery from '~/boards/graphql/client/active_board_item.query.graphql';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import { mockLabelList, mockIssue, DEFAULT_COLOR } from '../mock_data';

describe('Board card', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mockSetActiveBoardItemResolver = jest.fn();
  const mockSetSelectedBoardItemsResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setActiveBoardItem: mockSetActiveBoardItemResolver,
      setSelectedBoardItems: mockSetSelectedBoardItemsResolver,
    },
  });

  // this particular mount component needs to be used after the root beforeEach because it depends on list being initialized
  const mountComponent = ({
    propsData = {},
    provide = {},
    stubs = { BoardCardInner },
    item = mockIssue,
    selectedBoardItems = [],
    activeBoardItem = {},
  } = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: isShowingLabelsQuery,
      data: {
        isShowingLabels: true,
      },
    });
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: selectedBoardItemsQuery,
      data: {
        selectedBoardItems,
      },
    });
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: { ...activeBoardItem, listId: 'gid://gitlab/List/1' },
      },
    });

    wrapper = shallowMountExtended(BoardCard, {
      apolloProvider: mockApollo,
      stubs: {
        ...stubs,
        BoardCardInner,
      },
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
        allowSubEpics: false,
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

  describe('when GlLabel is clicked in BoardCardInner', () => {
    it("doesn't call setSelectedBoardItemsMutation", () => {
      mountComponent();

      wrapper.findComponent(GlLabel).trigger('mouseup');

      expect(mockSetSelectedBoardItemsResolver).toHaveBeenCalledTimes(0);
    });
  });

  it('should not highlight the card by default', () => {
    mountComponent();

    expect(wrapper.classes()).not.toContain('is-active');
    expect(wrapper.classes()).not.toContain('multi-select');
  });

  it('should highlight the card with a correct style when selected', async () => {
    mountComponent({ activeBoardItem: { ...mockIssue, listId: 'gid://gitlab/List/1' } });
    await waitForPromises();

    expect(wrapper.classes()).toContain('is-active');
    expect(wrapper.classes()).not.toContain('multi-select');
  });

  it('should highlight the card with a correct style when multi-selected', () => {
    mountComponent({ selectedBoardItems: [mockIssue.id] });

    expect(wrapper.classes()).toContain('multi-select');
    expect(wrapper.classes()).not.toContain('is-active');
  });

  describe('when mouseup event is called on the card', () => {
    beforeEach(() => {
      mountComponent();
    });

    describe('when not using multi-select', () => {
      it('set active board item on client when clicking on card', async () => {
        await selectCard();
        await waitForPromises();

        expect(mockSetActiveBoardItemResolver).toHaveBeenCalledWith(
          {},
          {
            boardItem: mockIssue,
            listId: 'gid://gitlab/List/2',
          },
          expect.anything(),
          expect.anything(),
        );
      });
    });

    describe('when using multi-select', () => {
      beforeEach(() => {
        window.gon = { features: { boardMultiSelect: true } };
      });

      it('should call setSelectedBoardItemsMutation with correct parameters', async () => {
        await multiSelectCard();

        expect(mockSetSelectedBoardItemsResolver).toHaveBeenCalledTimes(1);
        expect(mockSetSelectedBoardItemsResolver).toHaveBeenCalledWith(
          expect.any(Object),
          {
            itemId: mockIssue.id,
          },
          expect.anything(),
          expect.anything(),
        );
      });
    });
  });

  describe('when card is loading', () => {
    it('card is disabled and user cannot drag', () => {
      mountComponent({ item: { ...mockIssue, isLoading: true } });

      expect(wrapper.classes()).toContain('is-disabled');
      expect(wrapper.classes()).not.toContain('gl-cursor-grab');
    });
  });

  describe('when card is not loading', () => {
    it('user can drag', () => {
      mountComponent();

      expect(wrapper.classes()).not.toContain('is-disabled');
      expect(wrapper.classes()).toContain('gl-cursor-grab');
    });
  });

  describe('when Epic colors are enabled', () => {
    it('applies the correct color', () => {
      window.gon.features = { epicColorHighlight: true };
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
});
