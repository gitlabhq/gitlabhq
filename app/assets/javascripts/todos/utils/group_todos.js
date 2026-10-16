import { TODO_TARGET_TYPE_ISSUE, TODO_TARGET_TYPE_WORK_ITEM } from '../constants';

/**
 * Key identifying the target of a to-do. `targetUrl` can point at a note (`#note_123`) or,
 * for failed MR pipelines, at the pipelines tab, so the target's own path is preferred.
 */
export const getTodoGroupKey = (todo) => {
  // One issue can have to-dos with both target types, so key them on parent and reference
  if ([TODO_TARGET_TYPE_ISSUE, TODO_TARGET_TYPE_WORK_ITEM].includes(todo.targetType)) {
    const parentId = todo.project?.id ?? todo.group?.id;
    const reference = todo.targetEntity?.reference;

    if (parentId && reference) return `${TODO_TARGET_TYPE_ISSUE}:${parentId}:${reference}`;
  }

  const path = todo.targetEntity?.webPath || todo.targetUrl?.split('#')[0];

  return path ? `${todo.targetType}:${path}` : todo.id;
};

/**
 * Groups to-dos by target, keeping the server's sort order: a group sits where its
 * first to-do appears, and to-dos keep their relative order inside the group.
 */
export const groupTodosByTarget = (todos) => {
  const groups = todos.reduce((acc, todo) => {
    const key = getTodoGroupKey(todo);
    const group = acc.get(key) ?? { key, todos: [] };

    // Updating an existing Map key keeps its original insertion position
    return acc.set(key, { ...group, todos: [...group.todos, todo] });
  }, new Map());

  return [...groups.values()];
};
