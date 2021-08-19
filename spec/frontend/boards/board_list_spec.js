import Draggable from 'vuedraggable';
import { DraggableItemTypes } from 'ee_else_ce/boards/constants';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import createComponent from 'jest/boards/board_list_helper';
import BoardCard from '~/boards/components/board_card.vue';
import eventHub from '~/boards/eventhub';

import { mockIssues } from './mock_data';

describe('Board list component', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findIssueCountLoadingIcon = () => wrapper.find('[data-testid="count-loading-icon"]');
  const findDraggable = () => wrapper.findComponent(Draggable);

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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('When Expanded', () => {
    beforeEach(() => {
      wrapper = createComponent();
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
      expect(wrapper.findAll(BoardCard).length).toBe(1);
    });

    it('sets data attribute with issue id', () => {
      expect(wrapper.find('.board-card').attributes('data-item-id')).toBe('1');
    });

    it('shows new issue form', async () => {
      wrapper.vm.toggleForm();

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-new-issue-form').exists()).toBe(true);
    });

    it('shows new issue form after eventhub event', async () => {
      eventHub.$emit(`toggle-issue-form-${wrapper.vm.list.id}`);

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-new-issue-form').exists()).toBe(true);
    });

    it('does not show new issue form for closed list', () => {
      wrapper.setProps({ list: { type: 'closed' } });
      wrapper.vm.toggleForm();

      expect(wrapper.find('.board-new-issue-form').exists()).toBe(false);
    });

    it('shows count list item', async () => {
      wrapper.vm.showCount = true;

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').exists()).toBe(true);

      expect(wrapper.find('.board-list-count').text()).toBe('Showing all issues');
    });

    it('sets data attribute with invalid id', async () => {
      wrapper.vm.showCount = true;

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').attributes('data-issue-id')).toBe('-1');
    });

    it('shows how many more issues to load', async () => {
      wrapper.vm.showCount = true;
      wrapper.setProps({ list: { issuesCount: 20 } });

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.board-list-count').text()).toBe('Showing 1 of 20 issues');
    });
  });

  describe('load more issues', () => {
    const actions = {
      fetchItemsForList: jest.fn(),
    };

    beforeEach(() => {
      wrapper = createComponent({
        listProps: { issuesCount: 25 },
      });
    });

    it('does not load issues if already loading', () => {
      wrapper = createComponent({
        actions,
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoadingMore: true } } },
      });
      wrapper.vm.listRef.dispatchEvent(new Event('scroll'));

      expect(actions.fetchItemsForList).not.toHaveBeenCalled();
    });

    it('shows loading more spinner', async () => {
      wrapper = createComponent({
        state: { listsFlags: { 'gid://gitlab/List/1': { isLoadingMore: true } } },
      });
      wrapper.vm.showCount = true;

      await wrapper.vm.$nextTick();

      expect(findIssueCountLoadingIcon().exists()).toBe(true);
    });
  });

  describe('max issue count warning', () => {
    beforeEach(() => {
      wrapper = createComponent({
        listProps: { issuesCount: 50 },
      });
    });

    describe('when issue count exceeds max issue count', () => {
      it('sets background to bg-danger-100', async () => {
        wrapper.setProps({ list: { issuesCount: 4, maxIssueCount: 3 } });

        await wrapper.vm.$nextTick();
        expect(wrapper.find('.bg-danger-100').exists()).toBe(true);
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      it('does not sets background to bg-danger-100', () => {
        wrapper.setProps({ list: { issuesCount: 2, maxIssueCount: 3 } });

        expect(wrapper.find('.bg-danger-100').exists()).toBe(false);
      });
    });

    describe('when list max issue count is 0', () => {
      it('does not sets background to bg-danger-100', () => {
        wrapper.setProps({ list: { maxIssueCount: 0 } });

        expect(wrapper.find('.bg-danger-100').exists()).toBe(false);
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

      describe('handleDragOnStart', () => {
        it('adds a class `is-dragging` to document body', () => {
          expect(document.body.classList.contains('is-dragging')).toBe(false);

          startDrag();

          expect(document.body.classList.contains('is-dragging')).toBe(true);
        });
      });

      describe('handleDragOnEnd', () => {
        beforeEach(() => {
          jest.spyOn(wrapper.vm, 'moveItem').mockImplementation(() => {});

          startDrag();
        });

        it('removes class `is-dragging` from document body', () => {
          document.body.classList.add('is-dragging');

          endDrag({
            oldIndex: 1,
            newIndex: 0,
            item: {
              dataset: {
                draggableItemType: DraggableItemTypes.card,
                itemId: mockIssues[0].id,
                itemIid: mockIssues[0].iid,
                itemPath: mockIssues[0].referencePath,
              },
            },
            to: { children: [], dataset: { listId: 'gid://gitlab/List/1' } },
            from: { dataset: { listId: 'gid://gitlab/List/2' } },
          });

          expect(document.body.classList.contains('is-dragging')).toBe(false);
        });

        it(`should not handle the event if the dragged item is not a "${DraggableItemTypes.card}"`, () => {
          endDrag({
            oldIndex: 1,
            newIndex: 0,
            item: {
              dataset: {
                draggableItemType: DraggableItemTypes.list,
                itemId: mockIssues[0].id,
                itemIid: mockIssues[0].iid,
                itemPath: mockIssues[0].referencePath,
              },
            },
            to: { children: [], dataset: { listId: 'gid://gitlab/List/1' } },
            from: { dataset: { listId: 'gid://gitlab/List/2' } },
          });

          expect(document.body.classList.contains('is-dragging')).toBe(true);
        });
      });
    });

    describe('when dragging is not allowed', () => {
      beforeEach(() => {
        wrapper = createComponent({
          componentProps: {
            disabled: true,
          },
        });
      });

      it('Draggable is not used', () => {
        expect(findDraggable().exists()).toBe(false);
      });
    });
  });
});
