import { GlIntersectionObserver } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import { nextTick } from 'vue';
import { DraggableItemTypes, ListType } from 'ee_else_ce/boards/constants';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import waitForPromises from 'helpers/wait_for_promises';
import createComponent from 'jest/boards/board_list_helper';
import { ESC_KEY_CODE } from '~/lib/utils/keycodes';
import BoardCard from '~/boards/components/board_card.vue';
import BoardCutLine from '~/boards/components/board_cut_line.vue';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';

import { mockIssues, mockIssuesMore, mockGroupIssuesResponse } from './mock_data';

describe('Board list component', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findDraggable = () => wrapper.findComponent(Draggable);
  const findMoveToPositionComponent = () => wrapper.findComponent(BoardCardMoveToPosition);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findBoardListCount = () => wrapper.find('.board-list-count');

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
        expect(block.attributes('class')).toContain(
          'gl-rounded-bottom-left-base gl-rounded-bottom-right-base',
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
});
