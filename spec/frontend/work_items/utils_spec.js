import { NEW_WORK_ITEM_IID } from '~/work_items/constants';
import {
  autocompleteDataSources,
  markdownPreviewPath,
  isReference,
  getWorkItemIcon,
  workItemRoadmapPath,
} from '~/work_items/utils';

describe('autocompleteDataSources', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns correct data sources for new work item in project context', () => {
    expect(
      autocompleteDataSources({
        fullPath: 'project/group',
        iid: NEW_WORK_ITEM_IID,
        workItemTypeId: 2,
      }),
    ).toEqual({
      commands:
        '/foobar/project/group/-/autocomplete_sources/commands?type=WorkItem&work_item_type_id=2',
      labels:
        '/foobar/project/group/-/autocomplete_sources/labels?type=WorkItem&work_item_type_id=2',
      members:
        '/foobar/project/group/-/autocomplete_sources/members?type=WorkItem&work_item_type_id=2',
      issues:
        '/foobar/project/group/-/autocomplete_sources/issues?type=WorkItem&work_item_type_id=2',
      mergeRequests:
        '/foobar/project/group/-/autocomplete_sources/merge_requests?type=WorkItem&work_item_type_id=2',
      epics: '/foobar/project/group/-/autocomplete_sources/epics?type=WorkItem&work_item_type_id=2',
    });
  });

  it('returns correct data sources', () => {
    expect(autocompleteDataSources({ fullPath: 'project/group', iid: '2' })).toEqual({
      commands: '/foobar/project/group/-/autocomplete_sources/commands?type=WorkItem&type_id=2',
      labels: '/foobar/project/group/-/autocomplete_sources/labels?type=WorkItem&type_id=2',
      members: '/foobar/project/group/-/autocomplete_sources/members?type=WorkItem&type_id=2',
      issues: '/foobar/project/group/-/autocomplete_sources/issues?type=WorkItem&type_id=2',
      mergeRequests:
        '/foobar/project/group/-/autocomplete_sources/merge_requests?type=WorkItem&type_id=2',
      epics: '/foobar/project/group/-/autocomplete_sources/epics?type=WorkItem&type_id=2',
    });
  });

  it('returns correct data sources for new work item in group context', () => {
    expect(
      autocompleteDataSources({
        fullPath: 'group',
        iid: NEW_WORK_ITEM_IID,
        isGroup: true,
        workItemTypeId: 2,
      }),
    ).toEqual({
      commands:
        '/foobar/groups/group/-/autocomplete_sources/commands?type=WorkItem&work_item_type_id=2',
      labels:
        '/foobar/groups/group/-/autocomplete_sources/labels?type=WorkItem&work_item_type_id=2',
      members:
        '/foobar/groups/group/-/autocomplete_sources/members?type=WorkItem&work_item_type_id=2',
      issues:
        '/foobar/groups/group/-/autocomplete_sources/issues?type=WorkItem&work_item_type_id=2',
      mergeRequests:
        '/foobar/groups/group/-/autocomplete_sources/merge_requests?type=WorkItem&work_item_type_id=2',
      epics: '/foobar/groups/group/-/autocomplete_sources/epics?type=WorkItem&work_item_type_id=2',
    });
  });

  it('returns correct data sources with group context', () => {
    expect(
      autocompleteDataSources({
        fullPath: 'group',
        iid: '2',
        isGroup: true,
      }),
    ).toEqual({
      commands: '/foobar/groups/group/-/autocomplete_sources/commands?type=WorkItem&type_id=2',
      labels: '/foobar/groups/group/-/autocomplete_sources/labels?type=WorkItem&type_id=2',
      members: '/foobar/groups/group/-/autocomplete_sources/members?type=WorkItem&type_id=2',
      issues: '/foobar/groups/group/-/autocomplete_sources/issues?type=WorkItem&type_id=2',
      mergeRequests:
        '/foobar/groups/group/-/autocomplete_sources/merge_requests?type=WorkItem&type_id=2',
      epics: '/foobar/groups/group/-/autocomplete_sources/epics?type=WorkItem&type_id=2',
    });
  });
});

describe('markdownPreviewPath', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns correct data sources', () => {
    expect(markdownPreviewPath({ fullPath: 'project/group', iid: '2' })).toBe(
      '/foobar/project/group/-/preview_markdown?target_type=WorkItem&target_id=2',
    );
  });

  it('returns correct data sources with group context', () => {
    expect(markdownPreviewPath({ fullPath: 'group', iid: '2', isGroup: true })).toBe(
      '/foobar/groups/group/-/preview_markdown?target_type=WorkItem&target_id=2',
    );
  });
});

describe('getWorkItemIcon', () => {
  it.each(['epic', 'issue-type-epic'])('returns epic icon in case of %s', (icon) => {
    expect(getWorkItemIcon(icon)).toBe('epic');
  });
});

describe('isReference', () => {
  it.each`
    referenceId                                | result
    ${'#101'}                                  | ${true}
    ${'&101'}                                  | ${true}
    ${'101'}                                   | ${false}
    ${'#'}                                     | ${false}
    ${'&'}                                     | ${false}
    ${' &101'}                                 | ${false}
    ${'gitlab-org&101'}                        | ${true}
    ${'gitlab-org/project-path#101'}           | ${true}
    ${'gitlab-org/sub-group/project-path#101'} | ${true}
    ${'gitlab-org'}                            | ${false}
    ${'gitlab-org101#'}                        | ${false}
    ${'gitlab-org101&'}                        | ${false}
    ${'#gitlab-org101'}                        | ${false}
    ${'&gitlab-org101'}                        | ${false}
  `('returns $result for $referenceId', ({ referenceId, result }) => {
    expect(isReference(referenceId)).toBe(result);
  });
});

describe('workItemRoadmapPath', () => {
  it('constructs a path to the roadmap page', () => {
    const path = workItemRoadmapPath('project/group', '2');
    expect(path).toBe(
      '/groups/project/group/-/roadmap?epic_iid=2&layout=MONTHS&timeframe_range_type=CURRENT_YEAR',
    );
  });
});
