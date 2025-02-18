import {
  NEW_WORK_ITEM_IID,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_EPIC,
  STATE_OPEN,
  STATE_CLOSED,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_REQUIREMENTS,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
  WORK_ITEM_TYPE_ENUM_TICKET,
  WORK_ITEM_TYPE_VALUE_EPIC,
  WORK_ITEM_TYPE_VALUE_INCIDENT,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_REQUIREMENTS,
  WORK_ITEM_TYPE_VALUE_TASK,
  WORK_ITEM_TYPE_VALUE_TEST_CASE,
  WORK_ITEM_TYPE_VALUE_TICKET,
} from '~/work_items/constants';
import {
  autocompleteDataSources,
  convertTypeEnumToName,
  markdownPreviewPath,
  newWorkItemPath,
  isReference,
  getWorkItemIcon,
  workItemRoadmapPath,
  saveToggleToLocalStorage,
  getToggleFromLocalStorage,
  makeDrawerUrlParam,
  makeDrawerItemFullPath,
  getItems,
  canRouterNav,
  formatSelectOptionForCustomField,
} from '~/work_items/utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { TYPE_EPIC } from '~/issues/constants';

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
      milestones:
        '/foobar/project/group/-/autocomplete_sources/milestones?type=WorkItem&work_item_type_id=2',
      iterations:
        '/foobar/project/group/-/autocomplete_sources/iterations?type=WorkItem&work_item_type_id=2',
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
      milestones: '/foobar/project/group/-/autocomplete_sources/milestones?type=WorkItem&type_id=2',
      iterations: '/foobar/project/group/-/autocomplete_sources/iterations?type=WorkItem&type_id=2',
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
      milestones:
        '/foobar/groups/group/-/autocomplete_sources/milestones?type=WorkItem&work_item_type_id=2',
      iterations:
        '/foobar/groups/group/-/autocomplete_sources/iterations?type=WorkItem&work_item_type_id=2',
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
      milestones: '/foobar/groups/group/-/autocomplete_sources/milestones?type=WorkItem&type_id=2',
      iterations: '/foobar/groups/group/-/autocomplete_sources/iterations?type=WorkItem&type_id=2',
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

describe('newWorkItemPath', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
  });

  it('returns correct path', () => {
    expect(newWorkItemPath({ fullPath: 'group/project' })).toBe(
      '/foobar/group/project/-/work_items/new',
    );
  });

  it('returns correct path for workItemType', () => {
    expect(
      newWorkItemPath({ fullPath: 'group/project', workItemTypeName: WORK_ITEM_TYPE_ENUM_ISSUE }),
    ).toBe('/foobar/group/project/-/issues/new');
  });

  it('returns correct data sources with group context', () => {
    expect(
      newWorkItemPath({
        fullPath: 'group',
        isGroup: true,
        workItemTypeName: WORK_ITEM_TYPE_ENUM_EPIC,
      }),
    ).toBe('/foobar/groups/group/-/epics/new');
  });

  it('appends a query string to the path', () => {
    expect(newWorkItemPath({ fullPath: 'project', query: '?foo=bar' })).toBe(
      '/foobar/project/-/work_items/new?foo=bar',
    );
  });
});

describe('convertTypeEnumToName', () => {
  it.each`
    name                                 | enumValue
    ${WORK_ITEM_TYPE_VALUE_EPIC}         | ${WORK_ITEM_TYPE_ENUM_EPIC}
    ${WORK_ITEM_TYPE_VALUE_INCIDENT}     | ${WORK_ITEM_TYPE_ENUM_INCIDENT}
    ${WORK_ITEM_TYPE_VALUE_ISSUE}        | ${WORK_ITEM_TYPE_ENUM_ISSUE}
    ${WORK_ITEM_TYPE_VALUE_KEY_RESULT}   | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
    ${WORK_ITEM_TYPE_VALUE_OBJECTIVE}    | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${WORK_ITEM_TYPE_VALUE_REQUIREMENTS} | ${WORK_ITEM_TYPE_ENUM_REQUIREMENTS}
    ${WORK_ITEM_TYPE_VALUE_TASK}         | ${WORK_ITEM_TYPE_ENUM_TASK}
    ${WORK_ITEM_TYPE_VALUE_TEST_CASE}    | ${WORK_ITEM_TYPE_ENUM_TEST_CASE}
    ${WORK_ITEM_TYPE_VALUE_TICKET}       | ${WORK_ITEM_TYPE_ENUM_TICKET}
  `('returns %name when given the enum %enumValue', ({ name, enumValue }) => {
    expect(convertTypeEnumToName(enumValue)).toBe(name);
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

describe('utils for remembering user showLabel preferences', () => {
  useLocalStorageSpy();

  afterEach(() => {
    localStorage.clear();
  });

  describe('saveToggleToLocalStorage', () => {
    it('saves the value to localStorage', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;

      expect(localStorage.getItem(TEST_KEY)).toBe(null);

      saveToggleToLocalStorage(TEST_KEY, true);
      expect(localStorage.setItem).toHaveBeenCalled();
      expect(localStorage.getItem(TEST_KEY)).toBe(true);
    });
  });

  describe('getToggleFromLocalStorage', () => {
    it('defaults to true when there is no value from localStorage and no default value is passed', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;

      expect(localStorage.getItem(TEST_KEY)).toBe(null);

      const result = getToggleFromLocalStorage(TEST_KEY);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(result).toBe(true);
    });

    it('returns the default boolean value passed when there is no value from localStorage', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;
      const DEFAULT_VALUE = false;

      expect(localStorage.getItem(TEST_KEY)).toBe(null);

      const result = getToggleFromLocalStorage(TEST_KEY, DEFAULT_VALUE);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(result).toBe(false);
    });

    it('returns the boolean value from localStorage if it exists', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;
      const DEFAULT_VALUE = true;

      localStorage.setItem(TEST_KEY, 'false');

      const newResult = getToggleFromLocalStorage(TEST_KEY, DEFAULT_VALUE);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(newResult).toBe(false);
    });
  });
});

describe('`makeDrawerItemFullPath`', () => {
  it('returns the items `fullPath` if present', () => {
    const result = makeDrawerItemFullPath(
      { fullPath: 'this/should/be/returned' },
      'this/should/not',
    );
    expect(result).toBe('this/should/be/returned');
  });
  it('returns the fallback `fullPath` if `activeItem` does not have a `referencePath`', () => {
    const result = makeDrawerItemFullPath({}, 'this/should/be/returned');
    expect(result).toBe('this/should/be/returned');
  });
  describe('when `activeItem` has a `referencePath`', () => {
    it('handles the default `issuableType` of `ISSUE`', () => {
      const result = makeDrawerItemFullPath(
        { referencePath: 'this/should/be/returned#100' },
        'this/should/not',
      );
      expect(result).toBe('this/should/be/returned');
    });
    it('handles case where `issuableType` is an `EPIC`', () => {
      const result = makeDrawerItemFullPath(
        { referencePath: 'this/should/be/returned&100' },
        'this/should/not',
        TYPE_EPIC,
      );
      expect(result).toBe('this/should/be/returned');
    });
  });
});

describe('`makeDrawerUrlParam`', () => {
  it('returns iid, full_path, and id', () => {
    const result = makeDrawerUrlParam(
      { id: 'gid://gitlab/Issue/1', iid: '123', fullPath: 'gitlab-org/gitlab' },
      'gitlab-org/gitlab',
    );
    expect(result).toEqual(
      btoa(JSON.stringify({ iid: '123', full_path: 'gitlab-org/gitlab', id: 1 })),
    );
  });
});

describe('`getItems`', () => {
  it('returns all children when showClosed flag is on', () => {
    const children = [
      { id: 1, state: STATE_OPEN },
      { id: 2, state: STATE_CLOSED },
    ];
    const result = getItems(true)(children);
    expect(result).toEqual(children);
  });

  it('returns only open children when showClosed flag is off', () => {
    const openChildren = [
      { id: 1, state: STATE_OPEN },
      { id: 2, state: STATE_OPEN },
    ];
    const closedChildren = [{ id: 3, state: STATE_CLOSED }];
    const children = openChildren.concat(closedChildren);
    const result = getItems(false)(children);
    expect(result).toEqual(openChildren);
  });
});

describe('canRouterNav', () => {
  const projectFullPath = 'gitlab-org/gitlab';
  const groupFullPath = 'gitlab-org';
  const projectWebUrl = (fullPath = projectFullPath) => `/${fullPath}/-/issues/1`;
  const groupWebUrl = (fullPath = groupFullPath) => `/groups/${fullPath}/-/epics/1`;
  it.each`
    contextFullPath    | targetWebUrl                                | contextIsGroup | issueAsWorkItem | shouldRouterNav
    ${projectFullPath} | ${projectWebUrl()}                          | ${false}       | ${false}        | ${false}
    ${projectFullPath} | ${projectWebUrl()}                          | ${false}       | ${true}         | ${true}
    ${projectFullPath} | ${projectWebUrl('gitlab-org/gitlab-other')} | ${false}       | ${false}        | ${false}
    ${projectFullPath} | ${projectWebUrl('gitlab-org/gitlab-other')} | ${false}       | ${true}         | ${false}
    ${groupFullPath}   | ${groupWebUrl()}                            | ${true}        | ${false}        | ${true}
    ${groupFullPath}   | ${groupWebUrl()}                            | ${true}        | ${true}         | ${true}
    ${groupFullPath}   | ${groupWebUrl('gitlab-other')}              | ${true}        | ${false}        | ${false}
    ${groupFullPath}   | ${groupWebUrl('gitlab-other')}              | ${true}        | ${true}         | ${false}
  `(
    `returns $shouldRouterNav when fullPath is $contextFullPath, webUrl is $targetWebUrl, isGroup is $contextIsGroup, and issueAsWorkItem is $issueAsWorkItem`,
    ({ contextFullPath, targetWebUrl, contextIsGroup, issueAsWorkItem, shouldRouterNav }) => {
      expect(
        canRouterNav({
          fullPath: contextFullPath,
          webUrl: targetWebUrl,
          isGroup: contextIsGroup,
          issueAsWorkItem,
        }),
      ).toBe(shouldRouterNav);
    },
  );
});

describe('formatSelectOptionForCustomField', () => {
  it('returns object with text and value properties', () => {
    const data = {
      id: 1,
      value: 'test',
    };
    const result = {
      text: 'test',
      value: 1,
    };

    expect(formatSelectOptionForCustomField(data)).toEqual(result);
  });
});
