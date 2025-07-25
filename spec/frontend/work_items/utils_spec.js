import {
  NEW_WORK_ITEM_IID,
  STATE_CLOSED,
  STATE_OPEN,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_REQUIREMENTS,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
  WORK_ITEM_TYPE_ENUM_TICKET,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_REQUIREMENTS,
  WORK_ITEM_TYPE_NAME_TASK,
  WORK_ITEM_TYPE_NAME_TEST_CASE,
  WORK_ITEM_TYPE_NAME_TICKET,
} from '~/work_items/constants';
import {
  autocompleteDataSources,
  convertTypeEnumToName,
  formatLabelForListbox,
  formatUserForListbox,
  markdownPreviewPath,
  newWorkItemPath,
  isReference,
  workItemRoadmapPath,
  saveToggleToLocalStorage,
  getToggleFromLocalStorage,
  makeDrawerUrlParam,
  makeDrawerItemFullPath,
  getItems,
  canRouterNav,
  formatSelectOptionForCustomField,
  preserveDetailsState,
  getParentGroupName,
  createBranchMRApiPathHelper,
  getNewWorkItemAutoSaveKey,
  getNewWorkItemWidgetsAutoSaveKey,
  getWorkItemWidgets,
  updateDraftWorkItemType,
  getDraftWorkItemType,
} from '~/work_items/utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { TYPE_EPIC } from '~/issues/constants';
import { workItemQueryResponse } from './mock_data';

describe('formatLabelForListbox', () => {
  const label = {
    __typename: 'Label',
    id: 'gid://gitlab/Label/1',
    title: 'Label 1',
    description: '',
    color: '#f00',
    textColor: '#00f',
  };

  it('formats as expected', () => {
    expect(formatLabelForListbox(label)).toEqual({
      text: 'Label 1',
      value: 'gid://gitlab/Label/1',
      color: '#f00',
    });
  });
});

describe('formatUserForListbox', () => {
  const user = {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '',
    webUrl: '',
    webPath: '/doe_I',
    name: 'John Doe',
    username: 'doe_I',
  };

  it('formats as expected', () => {
    expect(formatUserForListbox(user)).toEqual({
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      avatarUrl: '',
      webUrl: '',
      webPath: '/doe_I',
      name: 'John Doe',
      username: 'doe_I',
      text: 'John Doe',
      value: 'gid://gitlab/User/1',
    });
  });
});

describe('autocompleteDataSources when extensible reference filters enabled', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
    gon.features = { extensibleReferenceFilters: true };
  });

  it('returns correct data sources for new work item in project context', () => {
    const buildUrl = (endpoint) =>
      `/foobar/project/group/-/autocomplete_sources/${endpoint}?type=WorkItem&work_item_type_id=2`;

    expect(
      autocompleteDataSources({
        fullPath: 'project/group',
        iid: NEW_WORK_ITEM_IID,
        workItemTypeId: 2,
      }),
    ).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      issuesAlternative: buildUrl('issues'),
      workItems: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      contacts: buildUrl('contacts'),
      snippets: buildUrl('snippets'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });

  it('returns correct data sources', () => {
    const buildUrl = (endpoint) =>
      `/foobar/project/group/-/autocomplete_sources/${endpoint}?type=WorkItem&type_id=2`;

    expect(autocompleteDataSources({ fullPath: 'project/group', iid: '2' })).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      issuesAlternative: buildUrl('issues'),
      workItems: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      contacts: buildUrl('contacts'),
      snippets: buildUrl('snippets'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });

  it('returns correct data sources for new work item in group context', () => {
    const buildUrl = (endpoint) =>
      `/foobar/groups/group/-/autocomplete_sources/${endpoint}?type=WorkItem&work_item_type_id=2`;

    expect(
      autocompleteDataSources({
        fullPath: 'group',
        iid: NEW_WORK_ITEM_IID,
        isGroup: true,
        workItemTypeId: 2,
      }),
    ).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      issuesAlternative: buildUrl('issues'),
      workItems: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });

  it('returns correct data sources with group context', () => {
    const buildUrl = (endpoint) =>
      `/foobar/groups/group/-/autocomplete_sources/${endpoint}?type=WorkItem&type_id=2`;

    expect(
      autocompleteDataSources({
        fullPath: 'group',
        iid: '2',
        isGroup: true,
      }),
    ).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      issuesAlternative: buildUrl('issues'),
      workItems: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });
});

describe('autocompleteDataSources when extensible reference filters disabled', () => {
  beforeEach(() => {
    gon.relative_url_root = '/foobar';
    gon.features = { extensibleReferenceFilters: false };
  });

  it('returns correct data sources for new work item in project context', () => {
    const buildUrl = (endpoint) =>
      `/foobar/project/group/-/autocomplete_sources/${endpoint}?type=WorkItem&work_item_type_id=2`;

    expect(
      autocompleteDataSources({
        fullPath: 'project/group',
        iid: NEW_WORK_ITEM_IID,
        workItemTypeId: 2,
      }),
    ).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      contacts: buildUrl('contacts'),
      snippets: buildUrl('snippets'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });

  it('returns correct data sources', () => {
    const buildUrl = (endpoint) =>
      `/foobar/project/group/-/autocomplete_sources/${endpoint}?type=WorkItem&type_id=2`;

    expect(autocompleteDataSources({ fullPath: 'project/group', iid: '2' })).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      contacts: buildUrl('contacts'),
      snippets: buildUrl('snippets'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });

  it('returns correct data sources for new work item in group context', () => {
    const buildUrl = (endpoint) =>
      `/foobar/groups/group/-/autocomplete_sources/${endpoint}?type=WorkItem&work_item_type_id=2`;

    expect(
      autocompleteDataSources({
        fullPath: 'group',
        iid: NEW_WORK_ITEM_IID,
        isGroup: true,
        workItemTypeId: 2,
      }),
    ).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
    });
  });

  it('returns correct data sources with group context', () => {
    const buildUrl = (endpoint) =>
      `/foobar/groups/group/-/autocomplete_sources/${endpoint}?type=WorkItem&type_id=2`;

    expect(
      autocompleteDataSources({
        fullPath: 'group',
        iid: '2',
        isGroup: true,
      }),
    ).toEqual({
      commands: buildUrl('commands'),
      labels: buildUrl('labels'),
      members: buildUrl('members'),
      issues: buildUrl('issues'),
      mergeRequests: buildUrl('merge_requests'),
      epics: buildUrl('epics'),
      milestones: buildUrl('milestones'),
      iterations: buildUrl('iterations'),
      vulnerabilities: buildUrl('vulnerabilities'),
      wikis: buildUrl('wikis'),
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

  it('returns correct data sources with NEW_WORK_ITEM_IID', () => {
    expect(markdownPreviewPath({ fullPath: 'group', iid: NEW_WORK_ITEM_IID, isGroup: true })).toBe(
      '/foobar/groups/group/-/preview_markdown?target_type=WorkItem',
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
      newWorkItemPath({ fullPath: 'group/project', workItemType: WORK_ITEM_TYPE_NAME_ISSUE }),
    ).toBe('/foobar/group/project/-/issues/new');
  });

  it('returns correct data sources with group context', () => {
    expect(
      newWorkItemPath({
        fullPath: 'group',
        isGroup: true,
        workItemType: WORK_ITEM_TYPE_NAME_EPIC,
      }),
    ).toBe('/foobar/groups/group/-/epics/new');
  });

  it('appends a query string to the path', () => {
    expect(newWorkItemPath({ fullPath: 'project', query: '?foo=bar' })).toBe(
      '/foobar/project/-/work_items/new?foo=bar',
    );
  });

  it('returns `work_items` path for group issues', () => {
    expect(
      newWorkItemPath({
        fullPath: 'my-group',
        isGroup: true,
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
      }),
    ).toBe('/foobar/groups/my-group/-/work_items/new');
  });
});

describe('convertTypeEnumToName', () => {
  it.each`
    name                                | enumValue
    ${WORK_ITEM_TYPE_NAME_EPIC}         | ${WORK_ITEM_TYPE_ENUM_EPIC}
    ${WORK_ITEM_TYPE_NAME_INCIDENT}     | ${WORK_ITEM_TYPE_ENUM_INCIDENT}
    ${WORK_ITEM_TYPE_NAME_ISSUE}        | ${WORK_ITEM_TYPE_ENUM_ISSUE}
    ${WORK_ITEM_TYPE_NAME_KEY_RESULT}   | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
    ${WORK_ITEM_TYPE_NAME_OBJECTIVE}    | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${WORK_ITEM_TYPE_NAME_REQUIREMENTS} | ${WORK_ITEM_TYPE_ENUM_REQUIREMENTS}
    ${WORK_ITEM_TYPE_NAME_TASK}         | ${WORK_ITEM_TYPE_ENUM_TASK}
    ${WORK_ITEM_TYPE_NAME_TEST_CASE}    | ${WORK_ITEM_TYPE_ENUM_TEST_CASE}
    ${WORK_ITEM_TYPE_NAME_TICKET}       | ${WORK_ITEM_TYPE_ENUM_TICKET}
  `('returns %name when given the enum %enumValue', ({ name, enumValue }) => {
    expect(convertTypeEnumToName(enumValue)).toBe(name);
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

describe('getNewWorkItemAutoSaveKey', () => {
  let originalWindowLocation;

  beforeEach(() => {
    originalWindowLocation = window.location;
    delete window.location;
    window.location = new URL('https://gitlab.example.com');
  });

  afterEach(() => {
    window.location = originalWindowLocation;
  });

  it('returns autosave key for a new work item', () => {
    const autosaveKey = getNewWorkItemAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
      workItemType: 'issue',
    });
    expect(autosaveKey).toEqual('new-gitlab-org/gitlab-issue-draft');
  });

  it.each`
    locationSearch                            | expectedAutosaveKey
    ${'vulnerability_id=1'}                   | ${'new-gitlab-org/gitlab-issue-vulnerability_id=1-draft'}
    ${'discussion_to_resolve=2'}              | ${'new-gitlab-org/gitlab-issue-discussion_to_resolve=2-draft'}
    ${'issue[issue_type]=Issue'}              | ${'new-gitlab-org/gitlab-issue-issue%5Bissue_type%5D=Issue-draft'}
    ${'issuable_template=FeatureIssue'}       | ${'new-gitlab-org/gitlab-issue-issuable_template=FeatureIssue-draft'}
    ${'discussion_to_resolve=2&state=opened'} | ${'new-gitlab-org/gitlab-issue-discussion_to_resolve=2-draft'}
  `(
    'returns autosave key with query params $locationSearch',
    ({ locationSearch, expectedAutosaveKey }) => {
      window.location.search = locationSearch;
      const autosaveKey = getNewWorkItemAutoSaveKey({
        fullPath: 'gitlab-org/gitlab',
        workItemType: 'issue',
      });

      expect(autosaveKey).toEqual(expectedAutosaveKey);
    },
  );

  it('returns autosave key for new related item', () => {
    const autosaveKey = getNewWorkItemAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
      workItemType: 'issue',
      relatedItemId: 'gid://gitlab/WorkItem/22',
    });

    expect(autosaveKey).toEqual('new-gitlab-org/gitlab-issue-related-22-draft');
  });
});

describe('getNewWorkItemWidgetsAutoSaveKey', () => {
  it('returns autosave key for a new work item', () => {
    const autosaveKey = getNewWorkItemWidgetsAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
    });
    expect(autosaveKey).toEqual('new-gitlab-org/gitlab-widgets-draft');
  });

  it('returns autosave key for new related item', () => {
    const autosaveKey = getNewWorkItemWidgetsAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
      relatedItemId: 'gid://gitlab/WorkItem/22',
    });

    expect(autosaveKey).toEqual('new-gitlab-org/gitlab-related-22-widgets-draft');
  });
});

describe('getWorkItemWidgets', () => {
  it('returns the correct widgets for a work item', () => {
    const result = getWorkItemWidgets({
      workspace: {
        workItem: workItemQueryResponse.data.workItem,
      },
    });

    const { widgets } = workItemQueryResponse.data.workItem;
    expect(result).toEqual({
      TITLE: workItemQueryResponse.data.workItem.title,
      TYPE: workItemQueryResponse.data.workItem.workItemType,
      [WIDGET_TYPE_DESCRIPTION]: widgets.find((widget) => widget.type === WIDGET_TYPE_DESCRIPTION),
      [WIDGET_TYPE_ASSIGNEES]: widgets.find((widget) => widget.type === WIDGET_TYPE_ASSIGNEES),
      [WIDGET_TYPE_HIERARCHY]: widgets.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY),
    });
  });
});

describe('updateDraftWorkItemType', () => {
  useLocalStorageSpy();

  const workItemWidgetsAutosaveKey = 'autosave/new-gitlab-org/gitlab-widgets-draft';
  const workItemType = {
    id: 'gid://gitlab/WorkItemType/1',
    name: WORK_ITEM_TYPE_NAME_ISSUE,
    iconName: 'issue-type-issue',
  };

  afterEach(() => {
    localStorage.clear();
  });

  it('sets `TYPE` with workItemType to localStorage widgets drafts key when it does not exist', () => {
    updateDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      workItemType,
    });

    expect(localStorage.setItem).toHaveBeenCalledWith(
      workItemWidgetsAutosaveKey,
      JSON.stringify({ TYPE: workItemType }),
    );
  });

  it('updates `TYPE` with workItemType to localStorage widgets drafts key when it already exists', () => {
    localStorage.setItem(workItemWidgetsAutosaveKey, JSON.stringify({ TITLE: 'Some work item' }));

    updateDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      workItemType,
    });

    expect(localStorage.setItem).toHaveBeenCalledWith(
      workItemWidgetsAutosaveKey,
      JSON.stringify({ TITLE: 'Some work item', TYPE: workItemType }),
    );
  });

  it('updates `TYPE` with workItemType to localStorage widgets for related item drafts key when it already exists', () => {
    const workItemWidgetsKey = 'autosave/new-gitlab-org/gitlab-related-22-widgets-draft';
    localStorage.setItem(workItemWidgetsKey, JSON.stringify({ TITLE: 'Some work item' }));

    updateDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      relatedItemId: 'gid://gitlab/WorkItem/22',
      workItemType,
    });

    expect(localStorage.setItem).toHaveBeenCalledWith(
      workItemWidgetsKey,
      JSON.stringify({ TITLE: 'Some work item', TYPE: workItemType }),
    );
  });
});

describe('getDraftWorkItemType', () => {
  afterEach(() => {
    localStorage.clear();
  });

  it('gets `TYPE` from localStorage widgets draft when it exists', () => {
    localStorage.setItem(
      'autosave/new-gitlab-org/gitlab-widgets-draft',
      JSON.stringify({ TYPE: 'Issue' }),
    );
    const workItemType = getDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
    });

    expect(workItemType).toBe('Issue');
  });

  it('gets `TYPE` from localStorage widgets for related item draft when it exists', () => {
    localStorage.setItem(
      'autosave/new-gitlab-org/gitlab-related-22-widgets-draft',
      JSON.stringify({ TYPE: 'Issue' }),
    );
    const workItemType = getDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      relatedItemId: 'gid://gitlab/WorkItem/22',
    });

    expect(workItemType).toBe('Issue');
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

describe('getParentGroupName', () => {
  it('returns parent group name from namespace', () => {
    const namespaceFullName = 'Flightjs / Flight';
    expect(getParentGroupName(namespaceFullName)).toEqual('Flightjs');
  });
});

describe('preserveDetailsState', () => {
  const descriptionHtml = '<details><summary>Test</summary><p>Content</p></details>';
  let element;

  beforeEach(() => {
    element = document.createElement('div');
  });

  it('returns null when there are no open details elements', () => {
    element.innerHTML = '<details><summary>Test</summary><p>Content</p></details>';

    expect(preserveDetailsState(element, descriptionHtml)).toBe(null);
  });

  it('returns null when number of details elements does not match', () => {
    element.innerHTML = '<details open><summary>Test</summary><p>Content</p></details>';
    const newDescriptionHtml =
      '<details><summary>Test</summary><p>Content</p></details><details><summary>Test 2</summary><p>Content 2</p></details>';

    expect(preserveDetailsState(element, newDescriptionHtml)).toBe(null);
  });

  it('preserves open state of details elements', () => {
    element.innerHTML = '<details open><summary>Test</summary><p>Content</p></details>';

    expect(preserveDetailsState(element, descriptionHtml)).toBe(
      '<details open="true"><summary>Test</summary><p>Content</p></details>',
    );
  });

  it('handles multiple details elements', () => {
    element.innerHTML = `
      <details open><summary>Test 1</summary><p>Content 1</p></details>
      <details><summary>Test 2</summary><p>Content 2</p></details>
    `;
    const newDescriptionHtml = `
      <details><summary>Test 1</summary><p>Content 1</p></details>
      <details><summary>Test 2</summary><p>Content 2</p></details>
    `;

    expect(preserveDetailsState(element, newDescriptionHtml)).toBe(`
      <details open="true"><summary>Test 1</summary><p>Content 1</p></details>
      <details><summary>Test 2</summary><p>Content 2</p></details>
    `);
  });
});

describe('createBranch', () => {
  it('returns a "create branch" path when given fullPath', () => {
    expect(createBranchMRApiPathHelper.createBranch('myGroup/myProject')).toBe(
      '/myGroup/myProject/-/branches',
    );
  });
});

describe('createMR', () => {
  const fullPath = 'gitlab-org/gitlab';
  const workItemIID = '12';
  const sourceBranch = '12-fix';
  const targetBranch = 'main';

  it('returns MR url with target branch', () => {
    const path = createBranchMRApiPathHelper.createMR({
      fullPath,
      workItemIid: workItemIID,
      sourceBranch,
      targetBranch,
    });
    expect(path).toBe(
      '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bissue_iid%5D=12&merge_request%5Bsource_branch%5D=12-fix&merge_request%5Btarget_branch%5D=main',
    );
  });

  it('returns MR url without target branch', () => {
    const path = createBranchMRApiPathHelper.createMR({
      fullPath,
      workItemIid: workItemIID,
      sourceBranch,
    });
    expect(path).toBe(
      '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bissue_iid%5D=12&merge_request%5Bsource_branch%5D=12-fix',
    );
  });

  it('returns MR url with relative url', () => {
    gon.relative_url_root = '/foobar';

    const path = createBranchMRApiPathHelper.createMR({
      fullPath,
      workItemIid: workItemIID,
      sourceBranch,
    });
    expect(path).toBe(
      '/foobar/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bissue_iid%5D=12&merge_request%5Bsource_branch%5D=12-fix',
    );
  });

  it('returns url with encoded branch names', () => {
    const path = createBranchMRApiPathHelper.createMR({
      fullPath,
      workItemIid: workItemIID,
      sourceBranch: 'source-branch#1',
      targetBranch: 'target-branch#1',
    });

    expect(path).toBe(
      '/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bissue_iid%5D=12&merge_request%5Bsource_branch%5D=source-branch%231&merge_request%5Btarget_branch%5D=target-branch%231',
    );
  });
});
