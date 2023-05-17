import {
  autocompleteDataSources,
  markdownPreviewPath,
  getWorkItemTodoOptimisticResponse,
} from '~/work_items/utils';
import { workItemResponseFactory } from './mock_data';

describe('autocompleteDataSources', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns corrrect data sources', () => {
    expect(autocompleteDataSources('project/group', '2')).toMatchObject({
      commands: '/foobar/project/group/-/autocomplete_sources/commands?type=WorkItem&type_id=2',
      labels: '/foobar/project/group/-/autocomplete_sources/labels?type=WorkItem&type_id=2',
      members: '/foobar/project/group/-/autocomplete_sources/members?type=WorkItem&type_id=2',
    });
  });
});

describe('markdownPreviewPath', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns corrrect data sources', () => {
    expect(markdownPreviewPath('project/group', '2')).toEqual(
      '/foobar/project/group/preview_markdown?target_type=WorkItem&target_id=2',
    );
  });
});

describe('getWorkItemTodoOptimisticResponse', () => {
  it.each`
    scenario     | pendingTodo | result
    ${'empty'}   | ${false}    | ${0}
    ${'present'} | ${true}     | ${1}
  `('returns correct response when pending item list is $scenario', ({ pendingTodo, result }) => {
    const workItem = workItemResponseFactory({ canUpdate: true });
    expect(
      getWorkItemTodoOptimisticResponse({ workItem, pendingTodo }).workItemUpdate.workItem
        .widgets[0].currentUserTodos.edges.length,
    ).toBe(result);
  });
});
