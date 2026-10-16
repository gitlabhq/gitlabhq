import { getTodoGroupKey, groupTodosByTarget } from '~/todos/utils/group_todos';

const todo = (id, targetUrl, { targetType = 'MERGEREQUEST', targetEntity = {} } = {}) => ({
  id,
  targetUrl,
  targetType,
  targetEntity,
});

describe('group_todos', () => {
  describe('getTodoGroupKey', () => {
    it('uses the path of the target when available', () => {
      const buildFailedTodo = todo('1', '/group/project/-/merge_requests/1/pipelines', {
        targetEntity: { webPath: '/group/project/-/merge_requests/1' },
      });

      expect(getTodoGroupKey(buildFailedTodo)).toBe(
        'MERGEREQUEST:/group/project/-/merge_requests/1',
      );
    });

    it('combines the target type and the target URL', () => {
      expect(getTodoGroupKey(todo('1', '/group/project/-/merge_requests/1'))).toBe(
        'MERGEREQUEST:/group/project/-/merge_requests/1',
      );
    });

    it('ignores the note anchor of the target URL', () => {
      expect(getTodoGroupKey(todo('1', '/group/project/-/merge_requests/1#note_123'))).toBe(
        'MERGEREQUEST:/group/project/-/merge_requests/1',
      );
    });

    it.each(['ISSUE', 'WORKITEM'])(
      'uses the parent and the reference for %s to-dos',
      (targetType) => {
        const issueTodo = {
          ...todo('1', '/group/project/-/issues/1', {
            targetType,
            targetEntity: { reference: '#1', webPath: '/group/project/-/issues/1' },
          }),
          project: { id: 'gid://gitlab/Project/2' },
        };

        expect(getTodoGroupKey(issueTodo)).toBe('ISSUE:gid://gitlab/Project/2:#1');
      },
    );

    it('falls back to the to-do ID when there is no target', () => {
      expect(getTodoGroupKey(todo('1', null, { targetEntity: null }))).toBe('1');
    });
  });

  describe('groupTodosByTarget', () => {
    it('returns an empty list when there are no to-dos', () => {
      expect(groupTodosByTarget([])).toEqual([]);
    });

    it('groups to-dos by target, keeping the order of the first to-do of each group', () => {
      const todos = [
        todo('1', '/mr/1'),
        todo('2', '/issues/1', { targetType: 'ISSUE' }),
        todo('3', '/mr/1#note_1'),
        todo('4', '/mr/2'),
        todo('5', '/issues/1', { targetType: 'ISSUE' }),
      ];

      expect(groupTodosByTarget(todos)).toEqual([
        { key: 'MERGEREQUEST:/mr/1', todos: [todos[0], todos[2]] },
        { key: 'ISSUE:/issues/1', todos: [todos[1], todos[4]] },
        { key: 'MERGEREQUEST:/mr/2', todos: [todos[3]] },
      ]);
    });

    it('groups issue and work item to-dos on the same item', () => {
      const parentAndReference = {
        group: { id: 'gid://gitlab/Group/2' },
        targetEntity: { reference: '#1' },
      };
      const todos = [
        { ...todo('1', '/issues/1', { targetType: 'ISSUE' }), ...parentAndReference },
        { ...todo('2', '/work_items/1', { targetType: 'WORKITEM' }), ...parentAndReference },
      ];

      expect(groupTodosByTarget(todos)).toEqual([{ key: 'ISSUE:gid://gitlab/Group/2:#1', todos }]);
    });

    it('does not group targets of different types that share a URL', () => {
      const todos = [todo('1', '/same'), todo('2', '/same', { targetType: 'ISSUE' })];

      expect(groupTodosByTarget(todos)).toHaveLength(2);
    });
  });
});
