import { GlIntersectionObserver } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import { nextTick } from 'vue';
import { DraggableItemTypes, ListType } from 'ee_else_ce/boards/constants';
import { DETAIL_VIEW_QUERY_PARAM_NAME } from '~/work_items/constants';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import waitForPromises from 'helpers/wait_for_promises';
import createComponent from 'jest/boards/board_list_helper';
import { ESC_KEY_CODE } from '~/lib/utils/keycodes';
import BoardCard from '~/boards/components/board_card.vue';
import BoardCutLine from '~/boards/components/board_cut_line.vue';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { getParameterByName } from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';

import { mockIssues, mockIssuesMore, mockGroupIssuesResponse } from './mock_data';

jest.mock('~/lib/utils/url_utility');

describe('Board list component', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findDraggable = () => wrapper.findComponent(Draggable);
  const findMoveToPositionComponent = () => wrapper.findComponent(BoardCardMoveToPosition);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findBoardListCount = () => wrapper.find('.board-list-count');
  const findBoardCardButtons = () => wrapper.findAll('button.board-card-button');

  const maxIssueCountWarningClass = '.gl-bg-red-50';

  const triggerInfiniteScroll = () => findIntersectionObserver().vm.$emit('appear');

  const startDrag = (
    params = {
      item: {
        dataset: {
          draggableItemType: DraggableItemTypes.card,
        },
      },
    },
  ) => {
    findByTestId('tree-root-wrapper').vm.$emit('start', params);
  };

  const endDrag = (params) => {
    findByTestId('tree-root-wrapper').vm.$emit('end', params);
  };

  useFakeRequestAnimationFrame();

  describe('When Expanded', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        apolloQueryHandlers: [
          [listIssuesQuery, jest.fn().mockResolvedValue(mockGroupIssuesResponse())],
        ],
      });
      await waitForPromises();
    });

    it('renders component', () => {
      expect(wrapper.find('.board-list-component').exists()).toBe(true);
    });

    it('renders loading icon', () => {
      wrapper = createComponent({
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoading: true } } },
      });

      expect(findByTestId('board_list_loading').exists()).toBe(true);
    });

    it('renders issues', () => {
      expect(wrapper.findAllComponents(BoardCard).length).toBe(1);
    });

    it('sets data attribute with issue id', () => {
      expect(wrapper.find('.board-card').attributes('data-item-id')).toBe('gid://gitlab/Issue/436');
    });

    it('shows new issue form when showNewForm prop is true', async () => {
      wrapper = createComponent({
        componentProps: { showNewForm: true },
      });

      await nextTick();
      expect(wrapper.find('.board-new-issue-form').exists()).toBe(true);
    });

    it('does not show new issue form for closed list', async () => {
      wrapper = createComponent({
        listProps: {
          listType: ListType.closed,
        },
        componentProps: { showNewForm: true },
      });
      await waitForPromises();

      expect(wrapper.find('.board-new-issue-form').exists()).toBe(false);
    });

    it('renders the move to position icon', () => {
      expect(findMoveToPositionComponent().exists()).toBe(true);
    });
  });

  describe('when ListType is Closed', () => {
    beforeEach(() => {
      wrapper = createComponent({
        listProps: {
          listType: ListType.closed,
        },
      });
    });

    it('Board card move to position is not visible', () => {
      expect(findMoveToPositionComponent().exists()).toBe(false);
    });
  });

  describe('load more issues', () => {
    describe('when loading is not in progress', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          apolloQueryHandlers: [
            [
              listIssuesQuery,
              jest
                .fn()
                .mockResolvedValue(mockGroupIssuesResponse('gid://gitlab/List/1', mockIssuesMore)),
            ],
          ],
        });
        await waitForPromises();
      });

      it('has intersection observer when the number of board list items are more than 5', () => {
        expect(findIntersectionObserver().exists()).toBe(true);
      });

      it('shows count when loaded more items and correct data attribute', async () => {
        triggerInfiniteScroll();
        await waitForPromises();
        expect(findBoardListCount().exists()).toBe(true);
        expect(findBoardListCount().attributes('data-issue-id')).toBe('-1');
      });
    });
  });

  describe('max issue count warning', () => {
    describe('when issue count exceeds max issue count', () => {
      beforeEach(async () => {
        wrapper = createComponent({ listProps: { issuesCount: 4, maxIssueCount: 2 } });
        await waitForPromises();
      });
      it('sets background to warning color', () => {
        const block = wrapper.find(maxIssueCountWarningClass);

        expect(block.exists()).toBe(true);
        expect(block.attributes('class').split(' ')).toEqual(
          expect.arrayContaining(['gl-rounded-bl-base', 'gl-rounded-br-base']),
        );
      });
      it('shows cut line', () => {
        const cutline = wrapper.findComponent(BoardCutLine);
        expect(cutline.exists()).toBe(true);
        expect(cutline.props('cutLineText')).toEqual('Work in progress limit: 2');
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      beforeEach(async () => {
        wrapper = createComponent({ list: { issuesCount: 2, maxIssueCount: 3 } });
        await waitForPromises();
      });
      it('does not sets background to warning color', () => {
        expect(wrapper.find(maxIssueCountWarningClass).exists()).toBe(false);
      });
      it('does not show cut line', () => {
        expect(wrapper.findComponent(BoardCutLine).exists()).toBe(false);
      });
    });

    describe('when list max issue count is 0', () => {
      beforeEach(async () => {
        wrapper = createComponent({ list: { maxIssueCount: 0 } });
        await waitForPromises();
      });
      it('does not sets background to warning color', () => {
        expect(wrapper.find(maxIssueCountWarningClass).exists()).toBe(false);
      });
      it('does not show cut line', () => {
        expect(wrapper.findComponent(BoardCutLine).exists()).toBe(false);
      });
    });
  });

  describe('drag & drop issue', () => {
    describe('when dragging is allowed', () => {
      beforeEach(() => {
        wrapper = createComponent({
          componentProps: {
            disabled: false,
          },
        });
      });

      it('Draggable is used', () => {
        expect(findDraggable().exists()).toBe(true);
      });

      it('sets delay and delayOnTouchOnly attributes on board list', () => {
        const listEl = wrapper.findComponent({ ref: 'list' });

        expect(listEl.attributes('delay')).toBe('100');
        expect(listEl.attributes('delayontouchonly')).toBe('true');
      });

      describe('handleDragOnStart', () => {
        it('adds a class `is-dragging` to document body', () => {
          expect(document.body.classList.contains('is-dragging')).toBe(false);

          startDrag();

          expect(document.body.classList.contains('is-dragging')).toBe(true);
        });

        it('attaches `keyup` event listener on document', async () => {
          jest.spyOn(document, 'addEventListener');
          findDraggable().vm.$emit('start', {
            item: {
              dataset: {
                draggableItemType: DraggableItemTypes.card,
              },
            },
          });
          await nextTick();

          expect(document.addEventListener).toHaveBeenCalledWith('keyup', expect.any(Function));
        });
      });

      describe('handleDragOnEnd', () => {
        const getDragEndParam = (draggableItemType) => ({
          oldIndex: 1,
          newIndex: 0,
          item: {
            dataset: {
              draggableItemType,
              itemId: mockIssues[0].id,
              itemIid: mockIssues[0].iid,
              itemPath: mockIssues[0].referencePath,
            },
          },
          to: { children: [], dataset: { listId: 'gid://gitlab/List/1' } },
          from: { dataset: { listId: 'gid://gitlab/List/2' } },
        });

        beforeEach(() => {
          startDrag();
        });

        it('removes class `is-dragging` from document body', () => {
          document.body.classList.add('is-dragging');

          endDrag(getDragEndParam(DraggableItemTypes.card));

          expect(document.body.classList.contains('is-dragging')).toBe(false);
        });

        it(`should not handle the event if the dragged item is not a "${DraggableItemTypes.card}"`, () => {
          endDrag(getDragEndParam(DraggableItemTypes.list));

          expect(document.body.classList.contains('is-dragging')).toBe(true);
        });

        it('detaches `keyup` event listener on document', async () => {
          jest.spyOn(document, 'removeEventListener');

          findDraggable().vm.$emit('end', getDragEndParam(DraggableItemTypes.card));
          await nextTick();

          expect(document.removeEventListener).toHaveBeenCalledWith('keyup', expect.any(Function));
        });
      });

      describe('handleKeyUp', () => {
        it('dispatches `mouseup` event when Escape key is pressed', () => {
          jest.spyOn(document, 'dispatchEvent');

          document.dispatchEvent(
            new Event('keyup', {
              keyCode: ESC_KEY_CODE,
            }),
          );

          expect(document.dispatchEvent).toHaveBeenCalledWith(new Event('mouseup'));
        });
      });
    });

    describe('when dragging is not allowed', () => {
      beforeEach(() => {
        wrapper = createComponent({
          provide: {
            disabled: true,
          },
        });
      });

      it('Draggable is not used', () => {
        expect(findDraggable().exists()).toBe(false);
      });

      it('Board card move to position is not visible', () => {
        expect(findMoveToPositionComponent().exists()).toBe(false);
      });
    });
  });

  describe('when using keyboard', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        apolloQueryHandlers: [
          [
            listIssuesQuery,
            jest
              .fn()
              .mockResolvedValue(mockGroupIssuesResponse('gid://gitlab/List/1', mockIssuesMore)),
          ],
        ],
        mountOptions: { attachTo: document.body },
      });
      await waitForPromises();
    });

    it('traverses up and down cards in list', async () => {
      findBoardCardButtons().at(0).trigger('focusin');
      await findBoardCardButtons().at(0).trigger('keydown.down');
      expect(document.activeElement).toEqual(findBoardCardButtons().at(1).element);
      await findBoardCardButtons().at(1).trigger('keydown.up');
      expect(document.activeElement).toEqual(findBoardCardButtons().at(0).element);
    });
  });

  describe('when the URL contains a `show` parameter', () => {
    const mutationHandler = jest.fn();
    const listResolver = jest.fn().mockResolvedValue(mockGroupIssuesResponse());
    const { id, iid, referencePath } = mockIssues[0];
    const mountForShowParamTests = async (showParams = { id, iid, full_path: referencePath }) => {
      const show = btoa(JSON.stringify(showParams));
      setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);

      getParameterByName.mockReturnValue(show);

      wrapper = createComponent({
        apolloQueryHandlers: [[listIssuesQuery, listResolver]],
        apolloResolvers: {
          Mutation: {
            setActiveBoardItem: mutationHandler,
          },
        },
      });
      await waitForPromises();
    };
    it('calls `getParameterByName` to get the `show` parameter', async () => {
      await mountForShowParamTests();
      expect(getParameterByName).toHaveBeenCalledWith(DETAIL_VIEW_QUERY_PARAM_NAME);
    });

    describe('when the item is found in the list', () => {
      it('calls the `setActiveWorkItem` mutation', async () => {
        await mountForShowParamTests();
        expect(mutationHandler).toHaveBeenCalled();
      });
    });

    describe('when the item is not found in the list', () => {
      it('emits `cannot-find-active-item`', async () => {
        await mountForShowParamTests({
          id: 'gid://gitlab/Issue/9999',
          iid: '9999',
          full_path: 'does-not-match/at-all',
        });
        expect(wrapper.emitted('cannot-find-active-item')).toHaveLength(1);
      });
    });

    describe('when the list component has already tried to find the show parameter item in the list', () => {
      it('does not call `getParameterName` to get the `show` parameter', async () => {
        await mountForShowParamTests({
          id: 'gid://gitlab/Issue/9999',
          iid: '9999',
          full_path: 'does-not-match/at-all',
        });
        await wrapper.setProps({ filterParams: { first: 50 } });
        expect(listResolver).toHaveBeenCalledTimes(2);
        expect(getParameterByName).toHaveBeenCalledTimes(1);
      });
    });
  });
});
