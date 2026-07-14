import {
  CREATION_CONTEXT_LIST_ROUTE,
  STATE_CLOSED,
  STATE_OPEN,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_AWARD_EMOJI,
  WIDGET_TYPE_NOTIFICATIONS,
  WIDGET_TYPE_NOTES,
  WIDGET_TYPE_ERROR_TRACKING,
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  WIDGET_TYPE_CUSTOM_FIELDS,
  WIDGET_TYPE_DEVELOPMENT,
  WIDGET_TYPE_DESIGNS,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_LINKED_RESOURCES,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_LINKED_ITEMS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_PARTICIPANTS,
  WIDGET_TYPE_PROGRESS,
  WIDGET_TYPE_STATUS,
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
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_TIME_TRACKING,
  WIDGET_TYPE_VULNERABILITIES,
} from '~/work_items/constants';
import {
  autocompleteDataSources,
  convertTypeEnumToName,
  findAssigneesWidget,
  findAwardEmojiWidget,
  findBlockerLinkedItems,
  findDesignsWidget,
  findDevelopmentWidget,
  findErrorTrackingWidget,
  findHierarchyWidget,
  findMilestoneWidget,
  findNotificationsWidget,
  findNotesWidget,
  findOpenChildItemsCountsByType,
  findCrmContactsWidget,
  findCurrentUserTodosWidget,
  findCustomFieldsWidget,
  findColorWidget,
  findHealthStatusWidget,
  findIterationWidget,
  findLabelsWidget,
  findParticipantsWidget,
  findProgressWidget,
  findWeightWidget,
  findStatusWidget,
  findLinkedItemsWidget,
  findLinkedResourcesWidget,
  findStartAndDueDateWidget,
  findTimeTrackingWidget,
  findVulnerabilitiesWidget,
  getMetadataWidgetsFromWorkItem,
  formatLabelForListbox,
  formatUserForListbox,
  newWorkItemPath,
  getDisplayReference,
  isReference,
  workItemRoadmapPath,
  saveHiddenMetadataKeysToLocalStorage,
  getHiddenMetadataKeysFromLocalStorage,
  makeDetailPanelUrlParam,
  makeDetailPanelItemFullPath,
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
  setLastUsedWorkItemTypeIdForNamespace,
  getLastUsedWorkItemTypeIdForNamespace,
  combineWorkItemLists,
  isCurrentViewWorkItem,
  getSortValue,
} from '~/work_items/utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { TYPE_EPIC } from '~/issues/constants';
import {
  CLOSED_AT_ASC,
  CLOSED_AT_DESC,
  CREATED_ASC,
  CREATED_DESC,
  DUE_DATE_ASC,
  DUE_DATE_DESC,
  MILESTONE_DUE_ASC,
  MILESTONE_DUE_DESC,
  POPULARITY_ASC,
  POPULARITY_DESC,
  START_DATE_ASC,
  START_DATE_DESC,
  TITLE_ASC,
  TITLE_DESC,
  UPDATED_ASC,
  UPDATED_DESC,
} from '~/work_items/list/constants';
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

describe('autocompleteDataSources', () => {
  const pathsWithSnakeCase = {
    members: '/flightjs/Flight/-/autocomplete_sources/members?type=WorkItem&work_item_type_id=1',
    issues: '/flightjs/Flight/-/autocomplete_sources/issues?type=WorkItem&work_item_type_id=1',
    mergeRequests:
      '/flightjs/Flight/-/autocomplete_sources/merge_requests?type=WorkItem&work_item_type_id=1',
    labels: '/flightjs/Flight/-/autocomplete_sources/labels?type=WorkItem&work_item_type_id=1',
    milestones:
      '/flightjs/Flight/-/autocomplete_sources/milestones?type=WorkItem&work_item_type_id=1',
    commands: '/flightjs/Flight/-/autocomplete_sources/commands?type=WorkItem&work_item_type_id=1',
    snippets: '/flightjs/Flight/-/autocomplete_sources/snippets?type=WorkItem&work_item_type_id=1',
    contacts: '/flightjs/Flight/-/autocomplete_sources/contacts?type=WorkItem&work_item_type_id=1',
    wikis: '/flightjs/Flight/-/autocomplete_sources/wikis?type=WorkItem&work_item_type_id=1',
    epics: '/flightjs/Flight/-/autocomplete_sources/epics?type=WorkItem&work_item_type_id=1',
    iterations:
      '/flightjs/Flight/-/autocomplete_sources/iterations?type=WorkItem&work_item_type_id=1',
    vulnerabilities:
      '/flightjs/Flight/-/autocomplete_sources/vulnerabilities?type=WorkItem&work_item_type_id=1',
  };

  const pathsWithCamelCase = {
    members: '/flightjs/Flight/-/autocomplete_sources/members?type=WorkItem&work_item_type_id=1',
    issues: '/flightjs/Flight/-/autocomplete_sources/issues?type=WorkItem&work_item_type_id=1',
    mergeRequests:
      '/flightjs/Flight/-/autocomplete_sources/merge_requests?type=WorkItem&work_item_type_id=1',
    labels: '/flightjs/Flight/-/autocomplete_sources/labels?type=WorkItem&work_item_type_id=1',
    milestones:
      '/flightjs/Flight/-/autocomplete_sources/milestones?type=WorkItem&work_item_type_id=1',
    commands: '/flightjs/Flight/-/autocomplete_sources/commands?type=WorkItem&work_item_type_id=1',
    snippets: '/flightjs/Flight/-/autocomplete_sources/snippets?type=WorkItem&work_item_type_id=1',
    contacts: '/flightjs/Flight/-/autocomplete_sources/contacts?type=WorkItem&work_item_type_id=1',
    wikis: '/flightjs/Flight/-/autocomplete_sources/wikis?type=WorkItem&work_item_type_id=1',
    epics: '/flightjs/Flight/-/autocomplete_sources/epics?type=WorkItem&work_item_type_id=1',
    iterations:
      '/flightjs/Flight/-/autocomplete_sources/iterations?type=WorkItem&work_item_type_id=1',
    vulnerabilities:
      '/flightjs/Flight/-/autocomplete_sources/vulnerabilities?type=WorkItem&work_item_type_id=1',
  };

  describe('default', () => {
    it('returns paths', () => {
      expect(autocompleteDataSources(pathsWithCamelCase)).toEqual({
        ...pathsWithCamelCase,
        statuses: true,
      });
    });
  });

  describe('when sources contains merge_requests property', () => {
    it('returns paths with merge_requests converted to mergeRequests', () => {
      expect(autocompleteDataSources(pathsWithSnakeCase)).toEqual({
        ...pathsWithCamelCase,
        statuses: true,
      });
    });
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

  it('returns correct data sources with group context', () => {
    expect(newWorkItemPath({ fullPath: 'group', isGroup: true })).toBe(
      '/foobar/groups/group/-/work_items/new',
    );
  });

  it('appends a query string to the path', () => {
    expect(newWorkItemPath({ fullPath: 'project', query: '?foo=bar' })).toBe(
      '/foobar/project/-/work_items/new?foo=bar',
    );
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

describe('getDisplayReference', () => {
  it.each`
    workItemFullPath             | workItemReference                           | result
    ${'gitlab-org/project-path'} | ${'gitlab-org/project-path#101'}            | ${'#101'}
    ${'gitlab-org/project-path'} | ${'other-root/gitlab-org/project-path#101'} | ${'other-root/gitlab-org/project-path#101'}
    ${'gitlab-org'}              | ${'gitlab-org/project-path#101'}            | ${'gitlab-org/project-path#101'}
  `(
    'removes namespace from workItemReference if it matches workItemFullPath',
    ({ workItemFullPath, workItemReference, result }) => {
      expect(getDisplayReference(workItemFullPath, workItemReference)).toBe(result);
    },
  );
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

describe('utils for remembering hidden metadata keys', () => {
  useLocalStorageSpy();

  afterEach(() => {
    localStorage.clear();
  });

  describe('saveHiddenMetadataKeysToLocalStorage', () => {
    it('saves the array value to localStorage as JSON', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;

      expect(localStorage.getItem(TEST_KEY)).toBe(null);

      saveHiddenMetadataKeysToLocalStorage(TEST_KEY, ['label1', 'label2']);
      expect(localStorage.setItem).toHaveBeenCalled();
      expect(localStorage.getItem(TEST_KEY)).toBe('["label1","label2"]');
    });
  });

  describe('getHiddenMetadataKeysFromLocalStorage', () => {
    it('returns default empty array when there is no value from localStorage and no default value is passed', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;

      expect(localStorage.getItem(TEST_KEY)).toBe(null);

      const result = getHiddenMetadataKeysFromLocalStorage(TEST_KEY);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(result).toEqual([]);
    });

    it('returns an empty array when there is no value from localStorage', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;

      expect(localStorage.getItem(TEST_KEY)).toBe(null);

      const result = getHiddenMetadataKeysFromLocalStorage(TEST_KEY);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(result).toEqual([]);
    });

    it('returns the parsed array value from localStorage if it exists', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;
      const TEST_ARRAY = ['labels', 'weight', 'milestone'];

      localStorage.setItem(TEST_KEY, JSON.stringify(TEST_ARRAY));

      const result = getHiddenMetadataKeysFromLocalStorage(TEST_KEY);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(result).toEqual(TEST_ARRAY);
    });

    it('returns an empty array when stored value is invalid JSON', () => {
      const TEST_KEY = `test-key-${new Date().getTime}`;

      localStorage.setItem(TEST_KEY, 'invalid-json');

      const result = getHiddenMetadataKeysFromLocalStorage(TEST_KEY);
      expect(localStorage.getItem).toHaveBeenCalled();
      expect(result).toEqual([]);
    });
  });
});

describe('`makeDetailPanelItemFullPath`', () => {
  it('returns the items `fullPath` if present', () => {
    const result = makeDetailPanelItemFullPath(
      { fullPath: 'this/should/be/returned' },
      'this/should/not',
    );
    expect(result).toBe('this/should/be/returned');
  });
  it('returns the fallback `fullPath` if `activeItem` does not have a `referencePath`', () => {
    const result = makeDetailPanelItemFullPath({}, 'this/should/be/returned');
    expect(result).toBe('this/should/be/returned');
  });
  describe('when `activeItem` has a `referencePath`', () => {
    it('handles the default `issuableType` of `ISSUE`', () => {
      const result = makeDetailPanelItemFullPath(
        { referencePath: 'this/should/be/returned#100' },
        'this/should/not',
      );
      expect(result).toBe('this/should/be/returned');
    });
    it('handles case where `issuableType` is an `EPIC`', () => {
      const result = makeDetailPanelItemFullPath(
        { referencePath: 'this/should/be/returned&100' },
        'this/should/not',
        TYPE_EPIC,
      );
      expect(result).toBe('this/should/be/returned');
    });
  });
});

describe('`makeDetailPanelUrlParam`', () => {
  it('returns iid, full_path, and id', () => {
    const result = makeDetailPanelUrlParam(
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
      context: CREATION_CONTEXT_LIST_ROUTE,
      workItemType: 'issue',
    });
    expect(autosaveKey).toBe('new-gitlab-org/gitlab-list-route-issue-draft');
  });

  it.each`
    locationSearch                            | expectedAutosaveKey
    ${'vulnerability_id=1'}                   | ${'new-gitlab-org/gitlab-list-route-vulnerability_id=1-issue-draft'}
    ${'discussion_to_resolve=2'}              | ${'new-gitlab-org/gitlab-list-route-discussion_to_resolve=2-issue-draft'}
    ${'issue[issue_type]=Issue'}              | ${'new-gitlab-org/gitlab-list-route-issue%5Bissue_type%5D=Issue-issue-draft'}
    ${'issuable_template=FeatureIssue'}       | ${'new-gitlab-org/gitlab-list-route-issuable_template=FeatureIssue-issue-draft'}
    ${'discussion_to_resolve=2&state=opened'} | ${'new-gitlab-org/gitlab-list-route-discussion_to_resolve=2-issue-draft'}
  `(
    'returns autosave key with query params $locationSearch',
    ({ locationSearch, expectedAutosaveKey }) => {
      window.location.search = locationSearch;
      const autosaveKey = getNewWorkItemAutoSaveKey({
        fullPath: 'gitlab-org/gitlab',
        context: CREATION_CONTEXT_LIST_ROUTE,
        workItemType: 'issue',
      });

      expect(autosaveKey).toBe(expectedAutosaveKey);
    },
  );

  it('returns autosave key for new related item', () => {
    const autosaveKey = getNewWorkItemAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
      workItemType: 'issue',
      relatedItemId: 'gid://gitlab/WorkItem/22',
    });

    expect(autosaveKey).toBe('new-gitlab-org/gitlab-list-route-related-id-22-issue-draft');
  });
});

describe('getNewWorkItemWidgetsAutoSaveKey', () => {
  it('returns autosave key for a new work item', () => {
    const autosaveKey = getNewWorkItemWidgetsAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
    });
    expect(autosaveKey).toBe('new-gitlab-org/gitlab-list-route-widgets-draft');
  });

  it('returns autosave key for new related item', () => {
    const autosaveKey = getNewWorkItemWidgetsAutoSaveKey({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
      relatedItemId: 'gid://gitlab/WorkItem/22',
    });

    expect(autosaveKey).toBe('new-gitlab-org/gitlab-list-route-related-id-22-widgets-draft');
  });
});

describe('getWorkItemWidgets', () => {
  it('returns the correct widgets for a work item', () => {
    const result = getWorkItemWidgets({
      namespace: {
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

  const workItemWidgetsAutosaveKey = 'autosave/new-gitlab-org/gitlab-list-route-widgets-draft';
  const workItemType = {
    id: 'gid://gitlab/WorkItemType/1',
    name: WORK_ITEM_TYPE_NAME_ISSUE,
    iconName: 'work-item-issue',
  };

  afterEach(() => {
    localStorage.clear();
  });

  it('sets `TYPE` with workItemType to localStorage widgets drafts key when it does not exist', () => {
    updateDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
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
      context: CREATION_CONTEXT_LIST_ROUTE,
      workItemType,
    });

    expect(localStorage.setItem).toHaveBeenCalledWith(
      workItemWidgetsAutosaveKey,
      JSON.stringify({ TITLE: 'Some work item', TYPE: workItemType }),
    );
  });

  it('updates `TYPE` with workItemType to localStorage widgets for related item drafts key when it already exists', () => {
    const workItemWidgetsKey =
      'autosave/new-gitlab-org/gitlab-list-route-related-id-22-widgets-draft';
    localStorage.setItem(workItemWidgetsKey, JSON.stringify({ TITLE: 'Some work item' }));

    updateDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
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
      'autosave/new-gitlab-org/gitlab-list-route-widgets-draft',
      JSON.stringify({ TYPE: 'Issue' }),
    );
    const workItemType = getDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
    });

    expect(workItemType).toBe('Issue');
  });

  it('gets `TYPE` from localStorage widgets for related item draft when it exists', () => {
    localStorage.setItem(
      'autosave/new-gitlab-org/gitlab-list-route-related-id-22-widgets-draft',
      JSON.stringify({ TYPE: 'Issue' }),
    );
    const workItemType = getDraftWorkItemType({
      fullPath: 'gitlab-org/gitlab',
      context: CREATION_CONTEXT_LIST_ROUTE,
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

describe('getLastUsedWorkItemTypeIdForNamespace', () => {
  useLocalStorageSpy();

  afterEach(() => {
    localStorage.clear();
  });

  it('calls getItem on localStorage with the correct key', () => {
    getLastUsedWorkItemTypeIdForNamespace('gitlab-org/gitlab');
    expect(localStorage.getItem).toHaveBeenCalledWith('freq-wi-type:gitlab-org/gitlab');
  });
});

describe('setLastUsedWorkItemTypeIdForNamespace', () => {
  useLocalStorageSpy();

  afterEach(() => {
    localStorage.clear();
  });

  it('calls setItem on localStorage with the correct key and value', () => {
    setLastUsedWorkItemTypeIdForNamespace('gid://gitlab/WorkItems::Type/1', 'gitlab-org/gitlab');
    expect(localStorage.setItem).toHaveBeenCalledWith(
      'freq-wi-type:gitlab-org/gitlab',
      'gid://gitlab/WorkItems::Type/1',
    );
  });
});

describe('combineWorkItemLists', () => {
  describe('with the features data', () => {
    const baseSlimList = [
      { id: 1, features: { description: { description: 'This work item description' } } },
      { id: 2, features: { assignees: { assignees: { nodes: [{ name: 'John' }] } } } },
    ];
    const baseFullList = [
      {
        id: 1,
        features: { description: { description: 'This work item description full version' } },
      },
      { id: 2, features: { assignees: { assignees: [{ name: 'John Jack' }] } } },
      { id: 3, features: { labels: { labels: { title: 'workflow' } } } },
    ];

    describe('when slim list is empty', () => {
      describe('and full list is empty', () => {
        it('returns empty array', () => {
          expect(combineWorkItemLists([], [], true)).toEqual([]);
        });
      });

      describe('and full list has items', () => {
        it('returns the full list', () => {
          expect(combineWorkItemLists([], baseFullList, true)).toEqual(baseFullList);
        });
      });

      describe('when both lists have items', () => {
        describe('and slim list features have fewer keys than full list features', () => {
          it('prioritizes full list features', () => {
            const fullList = [
              { ...baseFullList[0], features: { ...baseFullList[0].features, otherProp: true } },
              baseFullList[1],
              baseFullList[2],
            ];
            const result = combineWorkItemLists(baseSlimList, fullList, true);
            expect(result).toEqual(fullList);
          });
        });

        describe('and slim list has items not in full list', () => {
          it('includes items from both lists', () => {
            const slimList = [
              ...baseSlimList,
              { id: 4, features: { labels: { labels: { title: 'slim workflow' } } } },
            ];
            const fullList = [
              baseFullList[0],
              baseFullList[1],
              { id: 3, features: { milestone: { title: 'full milestone' } } },
            ];
            const result = combineWorkItemLists(slimList, fullList, true);
            expect(result).toEqual(fullList);
          });
        });
      });
    });
  });

  describe('with the widget data', () => {
    const baseSlimList = [
      { id: 1, widgets: [{ type: 'DESCRIPTION', value: 'slim desc' }] },
      { id: 2, widgets: [{ type: 'ASSIGNEES', value: 'slim assignee' }] },
    ];
    const baseFullList = [
      { id: 1, widgets: [{ type: 'DESCRIPTION', value: 'full desc' }] },
      { id: 2, widgets: [{ type: 'ASSIGNEES', value: 'full assignee' }] },
      { id: 3, widgets: [{ type: 'LABELS', value: 'full label' }] },
    ];

    describe('when slim list is empty', () => {
      describe('and full list is empty', () => {
        it('returns empty array', () => {
          expect(combineWorkItemLists([], [])).toEqual([]);
        });
      });

      describe('and full list has items', () => {
        it('returns the full list', () => {
          expect(combineWorkItemLists([], baseFullList)).toEqual(baseFullList);
        });
      });
    });

    describe('when both lists have items', () => {
      describe('and slim list widgets have fewer keys than full list widgets', () => {
        it('prioritizes full list widgets', () => {
          const fullList = [
            { ...baseFullList[0], widgets: [{ ...baseFullList[0].widgets[0], otherProp: true }] },
            baseFullList[1],
            baseFullList[2],
          ];

          const result = combineWorkItemLists(baseSlimList, fullList);

          expect(result).toEqual([
            { ...fullList[0], widgets: [fullList[0].widgets[0]] },
            { ...fullList[1], widgets: [fullList[1].widgets[0]] },
            fullList[2],
          ]);
        });
      });

      describe('and full list widgets have more keys than slim list widgets', () => {
        it('prioritizes full list widgets', () => {
          const fullList = [
            { ...baseFullList[0], widgets: [{ ...baseFullList[0].widgets[0], otherProp: true }] },
            { ...baseFullList[1], widgets: [{ ...baseFullList[1].widgets[0], otherProp: true }] },
            baseFullList[2],
          ];

          const result = combineWorkItemLists(baseSlimList, fullList);

          expect(result).toEqual([
            { ...fullList[0], widgets: [fullList[0].widgets[0]] },
            { ...fullList[1], widgets: [fullList[1].widgets[0]] },
            fullList[2],
          ]);
        });
      });

      describe('and slim list has items not in full list', () => {
        it('includes items from both lists', () => {
          const slimList = [
            ...baseSlimList,
            { id: 4, widgets: [{ type: 'LABELS', value: 'slim label' }] },
          ];
          const fullList = [
            baseFullList[0],
            baseFullList[1],
            { id: 3, widgets: [{ type: 'MILESTONE', value: 'full milestone' }] },
          ];

          const result = combineWorkItemLists(slimList, fullList);

          expect(result).toEqual([
            { ...fullList[0], widgets: [fullList[0].widgets[0]] },
            { ...fullList[1], widgets: [fullList[1].widgets[0]] },
            fullList[2],
          ]);
        });
      });
    });
  });
});

describe('isCurrentViewWorkItem', () => {
  const createDescriptionWrapper = (issuableType) => {
    const wrapper = document.createElement('div');
    wrapper.classList.add('js-issuable-description-wrapper');
    if (issuableType) {
      wrapper.dataset.issuableType = issuableType;
    }
    document.body.appendChild(wrapper);
    return wrapper;
  };

  afterEach(() => {
    document.body.dataset.page = '';
    document.querySelector('.js-issuable-description-wrapper')?.remove();
  });

  it.each`
    issuableType  | description
    ${'incident'} | ${'Incident'}
    ${'ticket'}   | ${'Ticket'}
  `('returns false for $description pages', ({ issuableType }) => {
    document.body.dataset.page = 'projects:issues:show';
    createDescriptionWrapper(issuableType);

    expect(isCurrentViewWorkItem()).toBe(false);
  });

  it.each`
    page                           | description
    ${'groups:work_items:index'}   | ${'Group Work Items list'}
    ${'groups:epics:index'}        | ${'Group Epics list'}
    ${'groups:issues'}             | ${'Group Issues'}
    ${'groups:boards:index'}       | ${'Group Issues Board'}
    ${'groups:epic_boards:index'}  | ${'Group Epics Board'}
    ${'projects:work_items:index'} | ${'Project Work Items list'}
    ${'projects:issues:index'}     | ${'Project Issues list'}
    ${'projects:boards:index'}     | ${'Project Issues Board'}
    ${'groups:work_items:show'}    | ${'Group Work Item detail'}
    ${'groups:epics:show'}         | ${'Group Epic detail'}
    ${'projects:work_items:show'}  | ${'Project Work Item detail'}
    ${'projects:issues:show'}      | ${'Project Issue detail'}
  `('returns true for $description view ($page)', ({ page }) => {
    document.body.dataset.page = page;

    expect(isCurrentViewWorkItem()).toBe(true);
  });

  it.each`
    page                              | description
    ${'projects:merge_requests:show'} | ${'Merge Request detail'}
    ${'projects:pipelines:show'}      | ${'Pipeline detail'}
    ${''}                             | ${'empty page'}
  `('returns false for $description view ($page)', ({ page }) => {
    document.body.dataset.page = page;

    expect(isCurrentViewWorkItem()).toBe(false);
  });
});

describe('findAssigneesWidget', () => {
  const assigneesWidget = { type: WIDGET_TYPE_ASSIGNEES, assignees: { nodes: [] } };
  const featuresAssignees = { allowsMultipleAssignees: true, assignees: { nodes: [] } };

  it('returns features.assignees when present', () => {
    const workItem = {
      features: { assignees: featuresAssignees },
      widgets: [assigneesWidget],
    };

    expect(findAssigneesWidget(workItem)).toBe(featuresAssignees);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [assigneesWidget] };

    expect(findAssigneesWidget(workItem)).toBe(assigneesWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findAssigneesWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('getMetadataWidgetsFromWorkItem', () => {
  const labelsWidget = { type: WIDGET_TYPE_LABELS, labels: { nodes: [{ id: 'widgets-label' }] } };
  const weightWidget = { type: WIDGET_TYPE_WEIGHT, weight: 1 };
  const milestoneWidget = { type: WIDGET_TYPE_MILESTONE, milestone: { id: 'milestone-1' } };

  describe('when a widget is only available on `widgets`', () => {
    it('builds the map from `widgets`', () => {
      const workItem = { widgets: [labelsWidget, milestoneWidget] };

      expect(getMetadataWidgetsFromWorkItem(workItem)).toEqual({
        [WIDGET_TYPE_LABELS]: labelsWidget,
        [WIDGET_TYPE_MILESTONE]: milestoneWidget,
      });
    });
  });

  describe('when a widget is available on `features`', () => {
    it('reads the widget from `features` instead of `widgets`', () => {
      const featuresLabels = { labels: { nodes: [{ id: 'features-label' }] } };
      const featuresWeight = { weight: 5 };
      const workItem = {
        widgets: [labelsWidget, weightWidget, milestoneWidget],
        features: { labels: featuresLabels, weight: featuresWeight },
      };

      expect(getMetadataWidgetsFromWorkItem(workItem)).toEqual({
        [WIDGET_TYPE_LABELS]: { type: WIDGET_TYPE_LABELS, ...featuresLabels },
        [WIDGET_TYPE_WEIGHT]: { type: WIDGET_TYPE_WEIGHT, ...featuresWeight },
        [WIDGET_TYPE_MILESTONE]: milestoneWidget,
      });
    });

    it('ignores feature values that are absent or empty', () => {
      const workItem = {
        widgets: [weightWidget, labelsWidget],
        features: { weight: null, healthStatus: undefined, labels: {} },
      };

      expect(getMetadataWidgetsFromWorkItem(workItem)).toEqual({
        [WIDGET_TYPE_WEIGHT]: weightWidget,
        // an empty `features.labels` must not clobber the widgets value
        [WIDGET_TYPE_LABELS]: labelsWidget,
      });
    });
  });

  describe('when the work item has no widgets or features', () => {
    it('returns an empty map', () => {
      expect(getMetadataWidgetsFromWorkItem(undefined)).toEqual({});
      expect(getMetadataWidgetsFromWorkItem({})).toEqual({});
    });
  });
});

describe('getSortValue', () => {
  const mockItem = {
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2024-02-20T14:30:00Z',
    closedAt: '2024-03-10T16:45:00Z',
    title: 'Test Work Item',
    widgets: [
      {
        type: WIDGET_TYPE_AWARD_EMOJI,
        upvotes: 5,
      },
      {
        type: WIDGET_TYPE_START_AND_DUE_DATE,
        dueDate: '2024-05-15',
        startDate: '2024-05-01',
      },
      {
        type: WIDGET_TYPE_MILESTONE,
        milestone: {
          dueDate: '2024-04-30',
          startDate: '2024-04-01',
        },
      },
    ],
  };

  it.each`
    sortKey               | itemModifier                                          | expectedResult
    ${CREATED_ASC}        | ${(item) => item}                                     | ${new Date('2024-01-15T10:00:00Z')}
    ${CREATED_DESC}       | ${(item) => item}                                     | ${new Date('2024-01-15T10:00:00Z')}
    ${UPDATED_ASC}        | ${(item) => item}                                     | ${new Date('2024-02-20T14:30:00Z')}
    ${UPDATED_DESC}       | ${(item) => item}                                     | ${new Date('2024-02-20T14:30:00Z')}
    ${CLOSED_AT_ASC}      | ${(item) => item}                                     | ${new Date('2024-03-10T16:45:00Z')}
    ${CLOSED_AT_DESC}     | ${(item) => item}                                     | ${new Date('2024-03-10T16:45:00Z')}
    ${MILESTONE_DUE_ASC}  | ${(item) => item}                                     | ${new Date('2024-04-30')}
    ${MILESTONE_DUE_DESC} | ${(item) => item}                                     | ${new Date('2024-04-30')}
    ${DUE_DATE_ASC}       | ${(item) => item}                                     | ${new Date('2024-05-15')}
    ${DUE_DATE_DESC}      | ${(item) => item}                                     | ${new Date('2024-05-15')}
    ${START_DATE_ASC}     | ${(item) => item}                                     | ${new Date('2024-05-01')}
    ${START_DATE_DESC}    | ${(item) => item}                                     | ${new Date('2024-05-01')}
    ${TITLE_ASC}          | ${(item) => item}                                     | ${'test work item'}
    ${TITLE_DESC}         | ${(item) => item}                                     | ${'test work item'}
    ${TITLE_ASC}          | ${(item) => ({ ...item, title: 'MiXeD CaSe TiTlE' })} | ${'mixed case title'}
    ${POPULARITY_ASC}     | ${(item) => item}                                     | ${5}
    ${POPULARITY_DESC}    | ${(item) => item}                                     | ${5}
  `('returns $expectedResult for $sortKey', ({ sortKey, itemModifier, expectedResult }) => {
    const item = itemModifier(mockItem);
    const result = getSortValue(item, sortKey);
    expect(result).toEqual(expectedResult);
  });

  it.each`
    sortKey               | itemModifier                                                                                                                              | expectedResult
    ${CLOSED_AT_ASC}      | ${(item) => ({ ...item, closedAt: null })}                                                                                                | ${null}
    ${CLOSED_AT_DESC}     | ${(item) => ({ ...item, closedAt: null })}                                                                                                | ${null}
    ${TITLE_ASC}          | ${(item) => ({ ...item, title: null })}                                                                                                   | ${''}
    ${TITLE_DESC}         | ${(item) => ({ ...item, title: null })}                                                                                                   | ${''}
    ${POPULARITY_DESC}    | ${(item) => ({ ...item, widgets: item.widgets.map((w) => (w.type === WIDGET_TYPE_AWARD_EMOJI ? { ...w, upvotes: undefined } : w)) })}     | ${null}
    ${MILESTONE_DUE_ASC}  | ${(item) => ({ ...item, widgets: item.widgets.filter((w) => w.type !== WIDGET_TYPE_MILESTONE) })}                                         | ${null}
    ${MILESTONE_DUE_DESC} | ${(item) => ({ ...item, widgets: item.widgets.filter((w) => w.type !== WIDGET_TYPE_MILESTONE) })}                                         | ${null}
    ${MILESTONE_DUE_ASC}  | ${(item) => ({ ...item, widgets: item.widgets.map((w) => (w.type === WIDGET_TYPE_MILESTONE ? { ...w, milestone: {} } : w)) })}            | ${null}
    ${MILESTONE_DUE_DESC} | ${(item) => ({ ...item, widgets: item.widgets.map((w) => (w.type === WIDGET_TYPE_MILESTONE ? { ...w, milestone: {} } : w)) })}            | ${null}
    ${DUE_DATE_ASC}       | ${(item) => ({ ...item, widgets: item.widgets.filter((w) => w.type !== WIDGET_TYPE_START_AND_DUE_DATE) })}                                | ${null}
    ${DUE_DATE_DESC}      | ${(item) => ({ ...item, widgets: item.widgets.map((w) => (w.type === WIDGET_TYPE_START_AND_DUE_DATE ? { ...w, dueDate: null } : w)) })}   | ${null}
    ${START_DATE_ASC}     | ${(item) => ({ ...item, widgets: item.widgets.filter((w) => w.type !== WIDGET_TYPE_START_AND_DUE_DATE) })}                                | ${null}
    ${START_DATE_DESC}    | ${(item) => ({ ...item, widgets: item.widgets.map((w) => (w.type === WIDGET_TYPE_START_AND_DUE_DATE ? { ...w, startDate: null } : w)) })} | ${null}
    ${'UNKNOWN_SORT_KEY'} | ${(item) => item}                                                                                                                         | ${null}
    ${''}                 | ${(item) => item}                                                                                                                         | ${null}
  `('returns null for $sortKey', ({ sortKey, itemModifier, expectedResult }) => {
    const item = itemModifier(mockItem);
    const result = getSortValue(item, sortKey);
    expect(result).toEqual(expectedResult);
  });
});

describe('findMilestoneWidget', () => {
  const milestoneWidget = { type: WIDGET_TYPE_MILESTONE, milestone: { id: 'gid://m/1' } };
  const featuresMilestone = { milestone: { id: 'gid://m/2' } };

  it('returns features.milestone when present', () => {
    const workItem = {
      features: { milestone: featuresMilestone },
      widgets: [milestoneWidget],
    };

    expect(findMilestoneWidget(workItem)).toBe(featuresMilestone);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [milestoneWidget] };

    expect(findMilestoneWidget(workItem)).toBe(milestoneWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findMilestoneWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findHierarchyWidget', () => {
  const hierarchyWidget = { type: WIDGET_TYPE_HIERARCHY, hasChildren: true };
  const featuresHierarchy = { hasChildren: false };

  it('returns features.hierarchy when present', () => {
    const workItem = {
      features: { hierarchy: featuresHierarchy },
      widgets: [hierarchyWidget],
    };

    expect(findHierarchyWidget(workItem)).toBe(featuresHierarchy);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [hierarchyWidget] };

    expect(findHierarchyWidget(workItem)).toBe(hierarchyWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findHierarchyWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findAwardEmojiWidget', () => {
  const awardEmojiWidget = { type: WIDGET_TYPE_AWARD_EMOJI, awardEmoji: { nodes: [] } };
  const featuresAwardEmoji = { upvotes: 0, downvotes: 0, awardEmoji: { nodes: [] } };

  it('returns features.awardEmoji when present', () => {
    const workItem = {
      features: { awardEmoji: featuresAwardEmoji },
      widgets: [awardEmojiWidget],
    };

    expect(findAwardEmojiWidget(workItem)).toBe(featuresAwardEmoji);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [awardEmojiWidget] };

    expect(findAwardEmojiWidget(workItem)).toBe(awardEmojiWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findAwardEmojiWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findNotificationsWidget', () => {
  const notificationsWidget = { type: WIDGET_TYPE_NOTIFICATIONS, subscribed: true };
  const featuresNotifications = { subscribed: true };

  it('returns features.notifications when present', () => {
    const workItem = {
      features: { notifications: featuresNotifications },
      widgets: [notificationsWidget],
    };

    expect(findNotificationsWidget(workItem)).toBe(featuresNotifications);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [notificationsWidget] };

    expect(findNotificationsWidget(workItem)).toBe(notificationsWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findNotificationsWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findNotesWidget', () => {
  describe('when features.notes is present', () => {
    const featuresNotes = { discussionLocked: true };
    const notesWidget = { type: WIDGET_TYPE_NOTES, discussionLocked: false };
    let workItem;

    beforeEach(() => {
      workItem = {
        features: { notes: featuresNotes },
        widgets: [notesWidget],
      };
    });

    it('returns features.notes', () => {
      expect(findNotesWidget(workItem)).toBe(featuresNotes);
    });
  });

  describe('when features.notes is not present', () => {
    const notesWidget = { type: WIDGET_TYPE_NOTES, discussionLocked: false };
    let workItem;

    beforeEach(() => {
      workItem = { widgets: [notesWidget] };
    });

    it('falls back to widgets', () => {
      expect(findNotesWidget(workItem)).toBe(notesWidget);
    });
  });

  describe('when neither exists', () => {
    it('returns undefined', () => {
      expect(findNotesWidget({ widgets: [] })).toBeUndefined();
    });
  });
});

describe('findParticipantsWidget', () => {
  const participantsWidget = {
    type: WIDGET_TYPE_PARTICIPANTS,
    participants: { count: 1, nodes: [{ id: 'gid://gitlab/User/1' }] },
  };
  const featuresParticipants = {
    participants: { count: 2, nodes: [{ id: 'gid://gitlab/User/2' }] },
  };

  describe('when features.participants is present', () => {
    let workItem;

    beforeEach(() => {
      workItem = {
        features: { participants: featuresParticipants },
        widgets: [participantsWidget],
      };
    });

    it('returns features.participants', () => {
      expect(findParticipantsWidget(workItem)).toBe(featuresParticipants);
    });
  });

  describe('when features is not present', () => {
    let workItem;

    beforeEach(() => {
      workItem = { widgets: [participantsWidget] };
    });

    it('falls back to the widgets array', () => {
      expect(findParticipantsWidget(workItem)).toBe(participantsWidget);
    });
  });

  describe('when neither features nor widget is present', () => {
    it('returns undefined', () => {
      expect(findParticipantsWidget({ widgets: [] })).toBeUndefined();
    });
  });
});

describe('findErrorTrackingWidget', () => {
  const errorTrackingWidget = {
    type: WIDGET_TYPE_ERROR_TRACKING,
    identifier: '1',
    stackTrace: { nodes: [] },
    status: 'SUCCESS',
  };
  const featuresErrorTracking = { identifier: '1', stackTrace: { nodes: [] }, status: 'SUCCESS' };

  it('returns features.errorTracking when present', () => {
    const workItem = {
      features: { errorTracking: featuresErrorTracking },
      widgets: [errorTrackingWidget],
    };

    expect(findErrorTrackingWidget(workItem)).toBe(featuresErrorTracking);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [errorTrackingWidget] };

    expect(findErrorTrackingWidget(workItem)).toBe(errorTrackingWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findErrorTrackingWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findCrmContactsWidget', () => {
  const crmContactsWidget = { type: WIDGET_TYPE_CRM_CONTACTS, contacts: { nodes: [] } };
  const featuresCrmContacts = { contactsAvailable: true, contacts: { nodes: [] } };

  it('returns features.crmContacts when present', () => {
    const workItem = {
      features: { crmContacts: featuresCrmContacts },
      widgets: [crmContactsWidget],
    };

    expect(findCrmContactsWidget(workItem)).toBe(featuresCrmContacts);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [crmContactsWidget] };

    expect(findCrmContactsWidget(workItem)).toBe(crmContactsWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findCrmContactsWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findCurrentUserTodosWidget', () => {
  const currentUserTodosWidget = {
    type: WIDGET_TYPE_CURRENT_USER_TODOS,
    currentUserTodos: { nodes: [{ id: 'gid://gitlab/Todo/1', state: 'pending' }] },
  };
  const featuresCurrentUserTodos = {
    currentUserTodos: { nodes: [{ id: 'gid://gitlab/Todo/2', state: 'pending' }] },
  };

  describe('when features.currentUserTodos is present', () => {
    let workItem;

    beforeEach(() => {
      workItem = {
        features: { currentUserTodos: featuresCurrentUserTodos },
        widgets: [currentUserTodosWidget],
      };
    });

    it('returns features.currentUserTodos', () => {
      expect(findCurrentUserTodosWidget(workItem)).toBe(featuresCurrentUserTodos);
    });
  });

  describe('when features is not present', () => {
    let workItem;

    beforeEach(() => {
      workItem = { widgets: [currentUserTodosWidget] };
    });

    it('falls back to the widgets array', () => {
      expect(findCurrentUserTodosWidget(workItem)).toBe(currentUserTodosWidget);
    });
  });

  describe('when neither features nor widget is present', () => {
    it('returns undefined', () => {
      expect(findCurrentUserTodosWidget({ widgets: [] })).toBeUndefined();
    });
  });
});

describe('findLinkedResourcesWidget', () => {
  const linkedResourcesWidget = {
    type: WIDGET_TYPE_LINKED_RESOURCES,
    linkedResources: { nodes: [] },
  };
  const featuresLinkedResources = { linkedResources: { nodes: [] } };

  it('returns features.linkedResources when present', () => {
    const workItem = {
      features: { linkedResources: featuresLinkedResources },
      widgets: [linkedResourcesWidget],
    };

    expect(findLinkedResourcesWidget(workItem)).toBe(featuresLinkedResources);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [linkedResourcesWidget] };

    expect(findLinkedResourcesWidget(workItem)).toBe(linkedResourcesWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findLinkedResourcesWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findLinkedItemsWidget', () => {
  const linkedItemsWidget = {
    type: WIDGET_TYPE_LINKED_ITEMS,
    linkedItems: { nodes: [{ linkId: 'gid://gitlab/IssueLink/1', linkType: 'relates_to' }] },
  };
  const featuresLinkedItems = {
    linkedItems: { nodes: [{ linkId: 'gid://gitlab/IssueLink/2', linkType: 'relates_to' }] },
  };

  it('returns features.linkedItems when present', () => {
    const workItem = {
      features: { linkedItems: featuresLinkedItems },
      widgets: [linkedItemsWidget],
    };

    expect(findLinkedItemsWidget(workItem)).toBe(featuresLinkedItems);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [linkedItemsWidget] };

    expect(findLinkedItemsWidget(workItem)).toBe(linkedItemsWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findLinkedItemsWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findStartAndDueDateWidget', () => {
  const startAndDueDateWidget = {
    type: WIDGET_TYPE_START_AND_DUE_DATE,
    startDate: '2024-01-01',
    dueDate: '2024-01-31',
  };
  const featuresStartAndDueDate = { startDate: '2024-02-01', dueDate: '2024-02-28' };

  it('returns features.startAndDueDate when present', () => {
    const workItem = {
      features: { startAndDueDate: featuresStartAndDueDate },
      widgets: [startAndDueDateWidget],
    };

    expect(findStartAndDueDateWidget(workItem)).toBe(featuresStartAndDueDate);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [startAndDueDateWidget] };

    expect(findStartAndDueDateWidget(workItem)).toBe(startAndDueDateWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findStartAndDueDateWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findLabelsWidget', () => {
  const labelsWidget = {
    type: WIDGET_TYPE_LABELS,
    allowsScopedLabels: false,
    labels: { nodes: [{ id: 'gid://gitlab/Label/1', title: 'bug' }] },
  };
  const featuresLabels = {
    allowsScopedLabels: true,
    labels: { nodes: [{ id: 'gid://gitlab/Label/2', title: 'feature' }] },
  };

  it('returns features.labels when present', () => {
    const workItem = {
      features: { labels: featuresLabels },
      widgets: [labelsWidget],
    };

    expect(findLabelsWidget(workItem)).toBe(featuresLabels);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [labelsWidget] };

    expect(findLabelsWidget(workItem)).toBe(labelsWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findLabelsWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findHealthStatusWidget', () => {
  const healthStatusWidget = {
    type: WIDGET_TYPE_HEALTH_STATUS,
    healthStatus: 'onTrack',
    rolledUpHealthStatus: [],
  };
  const featuresHealthStatus = {
    healthStatus: 'atRisk',
    rolledUpHealthStatus: [],
  };

  it('returns features.healthStatus when present', () => {
    const workItem = {
      features: { healthStatus: featuresHealthStatus },
      widgets: [healthStatusWidget],
    };

    expect(findHealthStatusWidget(workItem)).toBe(featuresHealthStatus);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [healthStatusWidget] };

    expect(findHealthStatusWidget(workItem)).toBe(healthStatusWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findHealthStatusWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findWeightWidget', () => {
  const weightWidget = {
    type: WIDGET_TYPE_WEIGHT,
    weight: 3,
    rolledUpWeight: 5,
    rolledUpCompletedWeight: 2,
  };
  const featuresWeight = {
    weight: 8,
    rolledUpWeight: 10,
    rolledUpCompletedWeight: 4,
  };

  it('returns features.weight when present', () => {
    const workItem = {
      features: { weight: featuresWeight },
      widgets: [weightWidget],
    };

    expect(findWeightWidget(workItem)).toBe(featuresWeight);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [weightWidget] };

    expect(findWeightWidget(workItem)).toBe(weightWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findWeightWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findStatusWidget', () => {
  const statusWidget = {
    type: WIDGET_TYPE_STATUS,
    status: { id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1', name: 'To do' },
  };
  const featuresStatus = {
    status: {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
      name: 'In progress',
    },
  };

  describe('when features.status is present', () => {
    let workItem;

    beforeEach(() => {
      workItem = {
        features: { status: featuresStatus },
        widgets: [statusWidget],
      };
    });

    it('returns features.status', () => {
      expect(findStatusWidget(workItem)).toBe(featuresStatus);
    });
  });

  describe('when features is not present', () => {
    let workItem;

    beforeEach(() => {
      workItem = { widgets: [statusWidget] };
    });

    it('falls back to the widgets array', () => {
      expect(findStatusWidget(workItem)).toBe(statusWidget);
    });
  });

  describe('when neither features nor widget is present', () => {
    it('returns undefined', () => {
      expect(findStatusWidget({ widgets: [] })).toBeUndefined();
    });
  });
});

describe('findCustomFieldsWidget', () => {
  const customFieldsWidget = {
    type: WIDGET_TYPE_CUSTOM_FIELDS,
    customFieldValues: [{ customField: { id: '1-text' }, value: 'Sample text' }],
  };
  const featuresCustomFields = {
    customFieldValues: [{ customField: { id: '1-number' }, value: 5 }],
  };

  describe('when features.customFields is present', () => {
    let workItem;

    beforeEach(() => {
      workItem = {
        features: { customFields: featuresCustomFields },
        widgets: [customFieldsWidget],
      };
    });

    it('returns features.customFields', () => {
      expect(findCustomFieldsWidget(workItem)).toBe(featuresCustomFields);
    });
  });

  describe('when features is not present', () => {
    let workItem;

    beforeEach(() => {
      workItem = { widgets: [customFieldsWidget] };
    });

    it('falls back to the widgets array', () => {
      expect(findCustomFieldsWidget(workItem)).toBe(customFieldsWidget);
    });
  });

  describe('when neither features nor widget is present', () => {
    it('returns undefined', () => {
      expect(findCustomFieldsWidget({ widgets: [] })).toBeUndefined();
    });
  });
});

describe('findIterationWidget', () => {
  const iterationWidget = {
    type: WIDGET_TYPE_ITERATION,
    iteration: { id: 'gid://gitlab/Iteration/1' },
  };
  const featuresIteration = {
    iteration: { id: 'gid://gitlab/Iteration/2' },
  };

  it('returns features.iteration when present', () => {
    const workItem = {
      features: { iteration: featuresIteration },
      widgets: [iterationWidget],
    };

    expect(findIterationWidget(workItem)).toBe(featuresIteration);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [iterationWidget] };

    expect(findIterationWidget(workItem)).toBe(iterationWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findIterationWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findColorWidget', () => {
  const colorWidget = {
    type: WIDGET_TYPE_COLOR,
    color: '#1068bf',
    textColor: '#FFFFFF',
  };
  const featuresColor = {
    color: '#e24329',
    textColor: '#FFFFFF',
  };

  it('returns features.color when present', () => {
    const workItem = {
      features: { color: featuresColor },
      widgets: [colorWidget],
    };

    expect(findColorWidget(workItem)).toBe(featuresColor);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [colorWidget] };

    expect(findColorWidget(workItem)).toBe(colorWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findColorWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findProgressWidget', () => {
  const progressWidget = {
    type: WIDGET_TYPE_PROGRESS,
    progress: 30,
    updatedAt: '2024-01-01T00:00:00Z',
  };
  const featuresProgress = {
    progress: 70,
    updatedAt: '2024-02-01T00:00:00Z',
  };

  it('returns features.progress when present', () => {
    const workItem = {
      features: { progress: featuresProgress },
      widgets: [progressWidget],
    };

    expect(findProgressWidget(workItem)).toBe(featuresProgress);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [progressWidget] };

    expect(findProgressWidget(workItem)).toBe(progressWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findProgressWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findDesignsWidget', () => {
  const designsWidget = {
    type: WIDGET_TYPE_DESIGNS,
    designCollection: { copyState: 'READY' },
  };
  const featuresDesigns = {
    designCollection: { copyState: 'IN_PROGRESS' },
  };

  it('returns features.designs when present', () => {
    const workItem = {
      features: { designs: featuresDesigns },
      widgets: [designsWidget],
    };

    expect(findDesignsWidget(workItem)).toBe(featuresDesigns);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [designsWidget] };

    expect(findDesignsWidget(workItem)).toBe(designsWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findDesignsWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findDevelopmentWidget', () => {
  const developmentWidget = {
    type: WIDGET_TYPE_DEVELOPMENT,
    willAutoCloseByMergeRequest: false,
    closingMergeRequests: { count: 0, nodes: [] },
  };
  const featuresDevelopment = {
    willAutoCloseByMergeRequest: true,
    closingMergeRequests: { count: 1, nodes: [] },
  };

  it('returns features.development when present', () => {
    const workItem = {
      features: { development: featuresDevelopment },
      widgets: [developmentWidget],
    };

    expect(findDevelopmentWidget(workItem)).toBe(featuresDevelopment);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [developmentWidget] };

    expect(findDevelopmentWidget(workItem)).toBe(developmentWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findDevelopmentWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findTimeTrackingWidget', () => {
  const timeTrackingWidget = {
    type: WIDGET_TYPE_TIME_TRACKING,
    timeEstimate: 0,
    humanReadableAttributes: { timeEstimate: '' },
    timelogs: { nodes: [] },
    totalTimeSpent: 0,
  };
  const featuresTimeTracking = {
    timeEstimate: 3600,
    humanReadableAttributes: { timeEstimate: '1h' },
    timelogs: { nodes: [] },
    totalTimeSpent: 1800,
  };

  it('returns features.timeTracking when present', () => {
    const workItem = {
      features: { timeTracking: featuresTimeTracking },
      widgets: [timeTrackingWidget],
    };

    expect(findTimeTrackingWidget(workItem)).toBe(featuresTimeTracking);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [timeTrackingWidget] };

    expect(findTimeTrackingWidget(workItem)).toBe(timeTrackingWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findTimeTrackingWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findVulnerabilitiesWidget', () => {
  const vulnerabilitiesWidget = {
    type: WIDGET_TYPE_VULNERABILITIES,
    relatedVulnerabilities: { nodes: [], count: 0 },
  };
  const featuresVulnerabilities = {
    relatedVulnerabilities: { nodes: [], count: 3 },
  };

  it('returns features.vulnerabilities when present', () => {
    const workItem = {
      features: { vulnerabilities: featuresVulnerabilities },
      widgets: [vulnerabilitiesWidget],
    };

    expect(findVulnerabilitiesWidget(workItem)).toBe(featuresVulnerabilities);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [vulnerabilitiesWidget] };

    expect(findVulnerabilitiesWidget(workItem)).toBe(vulnerabilitiesWidget);
  });

  it('returns undefined when neither exists', () => {
    expect(findVulnerabilitiesWidget({ widgets: [] })).toBeUndefined();
  });
});

describe('findBlockerLinkedItems', () => {
  const widgetNodes = [{ linkId: 'gid://gitlab/IssueLink/1', linkType: 'is_blocked_by' }];
  const featuresNodes = [{ linkId: 'gid://gitlab/IssueLink/2', linkType: 'is_blocked_by' }];
  const linkedItemsWidget = {
    type: WIDGET_TYPE_LINKED_ITEMS,
    linkedItems: { nodes: widgetNodes },
  };

  it('returns features.linkedItems.linkedItems.nodes when present', () => {
    const workItem = {
      features: { linkedItems: { linkedItems: { nodes: featuresNodes } } },
      widgets: [linkedItemsWidget],
    };

    expect(findBlockerLinkedItems(workItem)).toBe(featuresNodes);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [linkedItemsWidget] };

    expect(findBlockerLinkedItems(workItem)).toBe(widgetNodes);
  });

  it('returns undefined when neither exists', () => {
    expect(findBlockerLinkedItems({ widgets: [] })).toBeUndefined();
  });
});

describe('findOpenChildItemsCountsByType', () => {
  const widgetCounts = [
    { countsByState: { opened: 1, all: 1, closed: 0 }, workItemType: { name: 'Task' } },
  ];
  const featuresCounts = [
    { countsByState: { opened: 2, all: 2, closed: 0 }, workItemType: { name: 'Issue' } },
  ];
  const hierarchyWidget = {
    type: WIDGET_TYPE_HIERARCHY,
    rolledUpCountsByType: widgetCounts,
  };

  it('returns features.hierarchy.rolledUpCountsByType when present', () => {
    const workItem = {
      features: { hierarchy: { rolledUpCountsByType: featuresCounts } },
      widgets: [hierarchyWidget],
    };

    expect(findOpenChildItemsCountsByType(workItem)).toBe(featuresCounts);
  });

  it('falls back to widgets when features not present', () => {
    const workItem = { widgets: [hierarchyWidget] };

    expect(findOpenChildItemsCountsByType(workItem)).toBe(widgetCounts);
  });

  it('returns undefined when neither exists', () => {
    expect(findOpenChildItemsCountsByType({ widgets: [] })).toBeUndefined();
  });
});
