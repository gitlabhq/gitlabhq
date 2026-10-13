import { cloneDeep } from 'lodash-es';
import {
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_STATUS,
  WIDGET_TYPE_WEIGHT,
} from '~/work_items/constants';
import {
  addHierarchyChild,
  removeHierarchyChild,
  addHierarchyChildren,
  updateParent,
  setNewWorkItemCache,
  getNewWorkItemSharedCache,
  legacyGetNewWorkItemSharedCache,
  updateCacheAfterCreatingNote,
  updateCountsForParent,
} from '~/work_items/graphql/cache_utils';
import {
  findHierarchyWidget,
  findDescriptionWidget,
  findNotesWidget,
  getWorkItemWidgets,
  getNewWorkItemWidgetsAutoSaveKey,
} from '~/work_items/utils';
import { createIssuableCache, expectCacheHit } from 'helpers/apollo_cache_helper';
import { setCurrentUser } from 'helpers/current_user_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemCrmContactsQuery from '~/work_items/graphql/work_item_crm_contacts.query.graphql';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import workItemByIdQuery from '~/work_items/graphql/work_item_by_id.query.graphql';
import workItemLinkedItemsSlimQuery from '~/work_items/graphql/work_items_linked_items_slim.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import {
  linkedItems,
  currentAssignees,
  appliedLabels,
} from '~/graphql_shared/issuable_client_state';

import {
  workItemResponseFactory,
  workItemByIidResponseFactory,
  mockRolledUpCountsByType,
  workItemHierarchyTreeResponse,
  buildFeaturesTreeResponse,
  confidentialWorkItemTask,
  closedWorkItemTask,
  workItemTask,
  childrenWorkItems,
  createWorkItemNoteResponse,
  mockWorkItemNotesByIidResponse,
  mockCreateWorkItemDraftData,
  mockNewWorkItemCache,
  mockAssignees,
  mockLabels,
  mockWorkItemFeaturesData,
} from 'ee_else_ce_jest/work_items/mock_data';

describe('work items graphql cache utils', () => {
  const originalFeatures = window.gon.features;
  const id = 'gid://gitlab/WorkItem/2';
  const existingChildId = 'gid://gitlab/WorkItem/31';

  let cache;

  const treeVariables = (useWorkItemFeatures) => ({ id, useWorkItemFeatures });

  // The fixtures are shaped for the widgets path; on the features path each child carries
  // `features` instead, the same reshaping `buildFeaturesTreeResponse` applies to the tree.
  const asFeaturesChild = ({ widgets, ...child }) => ({
    ...child,
    features: mockWorkItemFeaturesData(),
  });

  const childFor = (useWorkItemFeatures, child) =>
    useWorkItemFeatures ? asFeaturesChild(child) : child;

  const seedTree = (useWorkItemFeatures) => {
    const response = useWorkItemFeatures
      ? buildFeaturesTreeResponse(workItemHierarchyTreeResponse)
      : workItemHierarchyTreeResponse;

    cache.writeQuery({
      query: getWorkItemTreeQuery,
      variables: treeVariables(useWorkItemFeatures),
      data: response.data,
    });
  };

  const readHierarchy = (useWorkItemFeatures) =>
    findHierarchyWidget(
      cache.readQuery({
        query: getWorkItemTreeQuery,
        variables: treeVariables(useWorkItemFeatures),
      })?.workItem,
    );

  const readChildIds = (useWorkItemFeatures) =>
    readHierarchy(useWorkItemFeatures).children.nodes.map((child) => child.id);

  beforeEach(() => {
    window.gon.features = {};
    // The new-work-item seed builds an author from the current user.
    setCurrentUser();
    cache = createIssuableCache();

    // Merge policies write these module-level vars, and nothing resets them between tests.
    linkedItems({});
    currentAssignees({});
    appliedLabels([]);
  });

  afterAll(() => {
    window.gon.features = originalFeatures;
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('addHierarchyChild on the $path path', ({ useWorkItemFeatures }) => {
    let newChild;

    beforeEach(() => {
      window.gon.features = { workItemFeaturesField: useWorkItemFeatures };
      newChild = childFor(useWorkItemFeatures, workItemTask);
    });

    describe('when the work item is in the cache', () => {
      beforeEach(() => {
        seedTree(useWorkItemFeatures);
        addHierarchyChild({ cache, id, workItem: newChild });
      });

      it('prepends the child to the tree', () => {
        expect(readChildIds(useWorkItemFeatures)).toEqual([newChild.id, existingChildId]);
      });

      it('marks the work item as having children', () => {
        expect(readHierarchy(useWorkItemFeatures).hasChildren).toBe(true);
      });

      it('leaves the tree query fully readable from the cache', () => {
        expectCacheHit(cache, {
          query: getWorkItemTreeQuery,
          variables: treeVariables(useWorkItemFeatures),
        });
      });

      // `children.count` is the only count the tree query selects, and addHierarchyChild
      // never writes it (it sets `widget.count`, which the document does not select).
      // See https://gitlab.com/gitlab-org/gitlab/-/work_items/629889
      it.todo('updates children.count to match the number of children');
    });

    describe('when the work item is not in the cache', () => {
      it('leaves the cache untouched', () => {
        const before = cache.extract();

        addHierarchyChild({ cache, id, workItem: newChild });

        expect(cache.extract()).toEqual(before);
      });
    });

    describe('when the child is added at an index', () => {
      beforeEach(() => {
        seedTree(useWorkItemFeatures);
        addHierarchyChild({ cache, id, workItem: newChild, atIndex: 1 });
      });

      it('inserts the child at that index', () => {
        expect(readChildIds(useWorkItemFeatures)).toEqual([existingChildId, newChild.id]);
      });
    });
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('addHierarchyChildren on the $path path', ({ useWorkItemFeatures }) => {
    let openChild;
    let closedChild;

    beforeEach(() => {
      window.gon.features = { workItemFeaturesField: useWorkItemFeatures };
      openChild = childFor(useWorkItemFeatures, confidentialWorkItemTask);
      closedChild = childFor(useWorkItemFeatures, closedWorkItemTask);
    });

    describe('when the work item is in the cache', () => {
      beforeEach(() => {
        seedTree(useWorkItemFeatures);
        addHierarchyChildren({ cache, id, newChildren: [closedChild, openChild] });
      });

      it('puts open children before the existing ones and closed children after', () => {
        expect(readChildIds(useWorkItemFeatures)).toEqual([
          openChild.id,
          existingChildId,
          closedChild.id,
        ]);
      });

      it('leaves the tree query fully readable from the cache', () => {
        expectCacheHit(cache, {
          query: getWorkItemTreeQuery,
          variables: treeVariables(useWorkItemFeatures),
        });
      });

      // The merged nodes are normalized references, so the dedupe filter at
      // cache_utils.js reads `undefined` for every existing id and lets duplicates through.
      // Fixing this is a prerequisite of
      // https://gitlab.com/gitlab-org/gitlab/-/work_items/629621
      it.todo('does not add a child that is already in the tree');
    });

    describe('when the work item has no cache id', () => {
      it('leaves the cache untouched', () => {
        seedTree(useWorkItemFeatures);
        const before = cache.extract();

        addHierarchyChildren({ cache, id: undefined, newChildren: [openChild] });

        expect(cache.extract()).toEqual(before);
      });
    });

    describe('when the work item is not in the cache', () => {
      it('leaves the cache untouched', () => {
        const before = cache.extract();

        addHierarchyChildren({ cache, id, newChildren: [openChild] });

        expect(cache.extract()).toEqual(before);
      });
    });
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('removeHierarchyChild on the $path path', ({ useWorkItemFeatures }) => {
    beforeEach(() => {
      window.gon.features = { workItemFeaturesField: useWorkItemFeatures };
    });

    describe('when the work item is in the cache', () => {
      beforeEach(() => {
        seedTree(useWorkItemFeatures);
        removeHierarchyChild({ cache, id, workItem: { id: existingChildId } });
      });

      it('removes the child from the tree', () => {
        expect(readChildIds(useWorkItemFeatures)).toEqual([]);
      });

      it('marks the work item as having no children', () => {
        expect(readHierarchy(useWorkItemFeatures).hasChildren).toBe(false);
      });

      it('leaves the tree query fully readable from the cache', () => {
        expectCacheHit(cache, {
          query: getWorkItemTreeQuery,
          variables: treeVariables(useWorkItemFeatures),
        });
      });
    });

    describe('when the work item is not in the cache', () => {
      it('leaves the cache untouched', () => {
        const before = cache.extract();

        removeHierarchyChild({ cache, id, workItem: { id: existingChildId } });

        expect(cache.extract()).toEqual(before);
      });
    });
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('setNewWorkItemCache on the $path path', ({ useWorkItemFeatures }) => {
    // `newWorkItemFullPath('gitlab-org', 'Epic')`, the path the draft is seeded under.
    const newWorkItemVariables = {
      fullPath: 'gitlab-org-epic-id',
      iid: 'new-work-item-iid',
      useWorkItemFeatures,
    };

    const seedCache = () =>
      setNewWorkItemCache({ ...mockNewWorkItemCache, useWorkItemFeatures, cache });

    const readWorkItem = () =>
      cache.readQuery({ query: workItemByIidQuery, variables: newWorkItemVariables })?.namespace
        ?.workItem;

    beforeEach(() => {
      setWindowLocation('https://gitlab.example.com');

      localStorage.setItem(
        `autosave/new-gitlab-org-list-route-epic-draft`,
        JSON.stringify(mockCreateWorkItemDraftData),
      );

      localStorage.setItem(
        `autosave/new-gitlab-org-list-route-widgets-draft`,
        JSON.stringify(getWorkItemWidgets(mockCreateWorkItemDraftData)),
      );
    });

    describe('when the form is opened without URL params', () => {
      beforeEach(async () => {
        await seedCache();
        await waitForPromises();
      });

      it('restores the drafted title', () => {
        expect(readWorkItem().title).toBe(mockCreateWorkItemDraftData.namespace.workItem.title);
      });

      it('restores the drafted description', () => {
        // `findDescriptionWidget` only reads the widgets path, so pick the feature directly.
        const workItem = readWorkItem();
        const description = workItem.features?.description ?? findDescriptionWidget(workItem);

        expect(description.description).toBe(
          findDescriptionWidget(mockCreateWorkItemDraftData.namespace.workItem).description,
        );
      });

      // The create form reads the draft back through these two documents. A cache read is
      // all-or-nothing, so a seed that misses one field sends the form to the network for
      // an IID that does not exist yet.
      it('seeds a work item the detail query can read in full', () => {
        expectCacheHit(cache, { query: workItemByIidQuery, variables: newWorkItemVariables });
      });

      it('seeds a work item the CRM contacts query can read in full', () => {
        expectCacheHit(cache, {
          query: workItemCrmContactsQuery,
          variables: newWorkItemVariables,
        });
      });
    });

    describe.each`
      locationSearchString          | expectedTitle
      ${'?vulnerability_id=1'}      | ${''}
      ${'?discussion_to_resolve=1'} | ${''}
      ${'?type=ISSUE'}              | ${mockCreateWorkItemDraftData.namespace.workItem.title}
    `(
      'when the URL params include $locationSearchString',
      ({ locationSearchString, expectedTitle }) => {
        beforeEach(async () => {
          setWindowLocation(`https://gitlab.example.com/${locationSearchString}`);

          await seedCache();
          await waitForPromises();
        });

        it('restores the title the params call for', () => {
          expect(readWorkItem().title).toBe(expectedTitle);
        });

        it('seeds a work item the detail query can read in full', () => {
          expectCacheHit(cache, { query: workItemByIidQuery, variables: newWorkItemVariables });
        });
      },
    );
  });

  describe('statuses for getNewWorkItemSharedCache', () => {
    const fullPath = 'gitlab-org';
    const context = 'list-route';

    const allowedStatus1 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
      category: 'to_do',
      name: 'To do',
      iconName: 'status-waiting',
      color: '#737278',
      __typename: 'WorkItemStatus',
    };
    const allowedStatus2 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
      category: 'in_progress',
      name: 'In progress',
      iconName: 'status-running',
      color: '#1f75cb',
      __typename: 'WorkItemStatus',
    };
    const disallowedStatus = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/99',
      category: 'done',
      name: 'Done',
      iconName: 'status-success',
      color: '#108548',
      __typename: 'WorkItemStatus',
    };

    const buildWidgetDefinitions = (overrides = {}) => [
      {
        __typename: 'WorkItemWidgetDefinitionStatus',
        type: WIDGET_TYPE_STATUS,
        allowedStatuses: [allowedStatus1, allowedStatus2],
        defaultOpenStatus: allowedStatus1,
        ...overrides,
      },
    ];

    const callGetNewWorkItemSharedCache = (widgetDefinitions) =>
      getNewWorkItemSharedCache({
        fullPath,
        context,
        workItemType: 'Issue',
        relatedItemId: null,
        isValidWorkItemDescription: false,
        workItemDescription: '',
        widgetDefinitions,
      });

    const setCachedStatus = (status) => {
      const widgetsKey = `autosave/${getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId: null })}`;
      localStorage.setItem(widgetsKey, JSON.stringify({ [WIDGET_TYPE_STATUS]: { status } }));
    };

    beforeEach(() => {
      localStorage.clear();
    });

    it('uses defaultOpenStatus when there is no cached status', () => {
      const { features } = callGetNewWorkItemSharedCache(buildWidgetDefinitions());

      expect(features.status.status).toEqual(allowedStatus1);
    });

    it('uses cached status when it exists in allowedStatuses', () => {
      setCachedStatus(allowedStatus2);

      const { features } = callGetNewWorkItemSharedCache(buildWidgetDefinitions());

      expect(features.status.status).toEqual(allowedStatus2);
    });

    it('falls back to defaultOpenStatus when cached status is not in allowedStatuses', () => {
      setCachedStatus(disallowedStatus);

      const { features } = callGetNewWorkItemSharedCache(buildWidgetDefinitions());

      expect(features.status.status).toEqual(allowedStatus1);
    });
  });

  // Regression guard for https://gitlab.com/gitlab-org/gitlab/-/work_items/608244
  // An empty feature object is truthy, so the create form renders it as an empty Status dropdown.
  describe('unsupported attributes for getNewWorkItemSharedCache', () => {
    const fullPath = 'gitlab-org';
    const context = 'list-route';

    const callForSupportedWidgetTypes = (supportedWidgetTypes) =>
      getNewWorkItemSharedCache({
        workItemAttributesWrapperOrder: [
          WIDGET_TYPE_STATUS,
          WIDGET_TYPE_ITERATION,
          WIDGET_TYPE_WEIGHT,
        ],
        fullPath,
        context,
        workItemType: 'Epic',
        relatedItemId: null,
        isValidWorkItemDescription: false,
        workItemDescription: '',
        widgetDefinitions: supportedWidgetTypes.map((type) => ({ type })),
      });

    beforeEach(() => {
      localStorage.clear();
    });

    it('nulls the attributes the work item type does not support', () => {
      const { features } = callForSupportedWidgetTypes([WIDGET_TYPE_WEIGHT]);

      expect(features.status).toBeNull();
      expect(features.iteration).toBeNull();
    });

    it('keeps the attributes the work item type supports', () => {
      const { features } = callForSupportedWidgetTypes([WIDGET_TYPE_WEIGHT]);

      expect(features.weight).toMatchObject({
        __typename: 'WorkItemWidgetWeight',
        weight: null,
      });
    });

    // Unsupported attributes are nulled rather than removed. Dropping the key instead would
    // leave a hole in the selection set, and a partial cache read is a cache miss.
    describe('when a type that supports neither status nor iteration is seeded', () => {
      const variables = {
        fullPath: 'gitlab-org-epic-id',
        iid: 'new-work-item-iid',
        useWorkItemFeatures: true,
      };

      beforeEach(async () => {
        await setNewWorkItemCache({
          ...mockNewWorkItemCache,
          widgetDefinitions: mockNewWorkItemCache.widgetDefinitions.filter(
            ({ type }) => ![WIDGET_TYPE_STATUS, WIDGET_TYPE_ITERATION].includes(type),
          ),
          useWorkItemFeatures: true,
          cache,
        });
        await waitForPromises();
      });

      it('leaves the work item query fully readable', () => {
        expectCacheHit(cache, { query: workItemByIidQuery, variables });
      });

      // Most features take `type` only from the widget definition spread, so a type whose
      // definitions omit one of them seeds an object without it and the read misses.
      // See https://gitlab.com/gitlab-org/gitlab/-/work_items/629890
      it.todo('seeds a widget type for features the work item type does not define');
    });
  });

  describe('CRM contacts for legacyGetNewWorkItemSharedCache', () => {
    const fullPath = 'gitlab-org';
    const context = 'list-route';

    const buildLegacyCache = () =>
      legacyGetNewWorkItemSharedCache({
        workItemAttributesWrapperOrder: [WIDGET_TYPE_CRM_CONTACTS],
        widgetDefinitions: [
          { __typename: 'WorkItemWidgetDefinitionGeneric', type: WIDGET_TYPE_CRM_CONTACTS },
        ],
        fullPath,
        context,
        workItemType: 'Issue',
        relatedItemId: null,
        isValidWorkItemDescription: false,
        workItemDescription: '',
      });

    const setCachedWidgets = (widgets) => {
      const widgetsKey = `autosave/${getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId: null })}`;
      localStorage.setItem(widgetsKey, JSON.stringify(widgets));
    };

    const findCrmWidget = (widgets) => widgets.find((w) => w.type === WIDGET_TYPE_CRM_CONTACTS);

    beforeEach(() => {
      localStorage.clear();
    });

    it('seeds empty contacts when there is no draft', () => {
      expect(findCrmWidget(buildLegacyCache().widgets).contacts.nodes).toEqual([]);
    });

    it('seeds the drafted contacts', () => {
      const contact = { id: 'gid://gitlab/CustomerRelations::Contact/1' };
      setCachedWidgets({ [WIDGET_TYPE_CRM_CONTACTS]: { contacts: { nodes: [contact] } } });

      expect(findCrmWidget(buildLegacyCache().widgets).contacts.nodes).toEqual([contact]);
    });

    // The base query no longer selects `contacts`, so a draft written from it has the widget
    // entry without that key. Reading it unguarded threw and broke the whole create form.
    it('seeds empty contacts when the draft entry has no contacts key', () => {
      setCachedWidgets({ [WIDGET_TYPE_CRM_CONTACTS]: { contactsAvailable: false } });

      expect(findCrmWidget(buildLegacyCache().widgets).contacts.nodes).toEqual([]);
    });
  });

  describe('statuses for legacyGetNewWorkItemSharedCache', () => {
    const fullPath = 'gitlab-org';
    const context = 'list-route';

    const allowedStatus1 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
      category: 'to_do',
      name: 'To do',
      iconName: 'status-waiting',
      color: '#737278',
      __typename: 'WorkItemStatus',
    };
    const allowedStatus2 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
      category: 'in_progress',
      name: 'In progress',
      iconName: 'status-running',
      color: '#1f75cb',
      __typename: 'WorkItemStatus',
    };
    const disallowedStatus = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/99',
      category: 'done',
      name: 'Done',
      iconName: 'status-success',
      color: '#108548',
      __typename: 'WorkItemStatus',
    };

    const widgetDefinitions = [
      {
        __typename: 'WorkItemWidgetDefinitionStatus',
        type: WIDGET_TYPE_STATUS,
        allowedStatuses: [allowedStatus1, allowedStatus2],
        defaultOpenStatus: allowedStatus1,
      },
    ];

    const setCachedStatus = (status) => {
      const widgetsKey = `autosave/${getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId: null })}`;
      localStorage.setItem(widgetsKey, JSON.stringify({ [WIDGET_TYPE_STATUS]: { status } }));
    };

    const buildLegacyCache = () =>
      legacyGetNewWorkItemSharedCache({
        workItemAttributesWrapperOrder: [WIDGET_TYPE_STATUS],
        widgetDefinitions,
        fullPath,
        context,
        workItemType: 'Issue',
        relatedItemId: null,
        isValidWorkItemDescription: false,
        workItemDescription: '',
      });

    const findStatusWidget = (widgets) => widgets.find((w) => w.type === WIDGET_TYPE_STATUS);

    beforeEach(() => {
      localStorage.clear();
    });

    it('uses defaultOpenStatus when there is no cached status', () => {
      const { widgets } = buildLegacyCache();

      expect(findStatusWidget(widgets).status).toEqual(allowedStatus1);
    });

    it('uses cached status when it exists in allowedStatuses', () => {
      setCachedStatus(allowedStatus2);

      const { widgets } = buildLegacyCache();

      expect(findStatusWidget(widgets).status).toEqual(allowedStatus2);
    });

    it('falls back to defaultOpenStatus when cached status is not in allowedStatuses', () => {
      setCachedStatus(disallowedStatus);

      const { widgets } = buildLegacyCache();

      expect(findStatusWidget(widgets).status).toEqual(allowedStatus1);
    });
  });

  describe('updateCacheAfterCreatingNote', () => {
    const findDiscussions = ({ namespace }) =>
      findNotesWidget(namespace.workItem).discussions.nodes;

    it('adds a new discussion to the notes widget', () => {
      const currentNotes = mockWorkItemNotesByIidResponse.data;
      const newNote = createWorkItemNoteResponse().data.createNote.note;

      expect(findDiscussions(currentNotes)).toHaveLength(3);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote);

      expect(findDiscussions(updatedNotes)).toHaveLength(4);
      expect(findDiscussions(updatedNotes).at(-1)).toBe(newNote.discussion);
    });

    it('adds a new discussion at the top when prepend is true', () => {
      const currentNotes = mockWorkItemNotesByIidResponse.data;
      const newNote = createWorkItemNoteResponse().data.createNote.note;

      expect(findDiscussions(currentNotes)).toHaveLength(3);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote, { prepend: true });

      expect(findDiscussions(updatedNotes)).toHaveLength(4);
      expect(findDiscussions(updatedNotes).at(0)).toBe(newNote.discussion);
    });

    it('does not modify notes widget when newNote is undefined', () => {
      const currentNotes = mockWorkItemNotesByIidResponse.data;
      const newNote = undefined;

      expect(findDiscussions(currentNotes)).toHaveLength(3);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote);

      expect(findDiscussions(updatedNotes)).toHaveLength(3);
    });

    it('does not add duplicate discussions', () => {
      const currentNotes = cloneDeep(mockWorkItemNotesByIidResponse.data);
      const newNote = createWorkItemNoteResponse().data.createNote.note;
      findDiscussions(currentNotes).push(newNote.discussion);

      expect(findDiscussions(currentNotes)).toHaveLength(4);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote);

      expect(findDiscussions(updatedNotes)).toHaveLength(4);
    });
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('updateCountsForParent on the $path path', ({ useWorkItemFeatures }) => {
    const workItemType = 'Task';
    // The features fixture ships an empty `rolledUpCountsByType`, so seed the same counts
    // the widgets side of the factory already carries.
    const parentData = workItemResponseFactory(
      useWorkItemFeatures
        ? {
            features: {
              hierarchy: {
                ...mockWorkItemFeaturesData().hierarchy,
                rolledUpCountsByType: mockRolledUpCountsByType,
              },
            },
          }
        : {},
    );
    const parentId = parentData.data.workItem.id;
    const variables = { id: parentId, useWorkItemFeatures };

    const countsFor = (workItem) =>
      findHierarchyWidget(workItem).rolledUpCountsByType.find(
        (counts) => counts.workItemType.name === workItemType,
      ).countsByState;

    const readCounts = () =>
      countsFor(cache.readQuery({ query: workItemByIdQuery, variables }).workItem);

    beforeEach(() => {
      window.gon.features = { workItemFeaturesField: useWorkItemFeatures };
    });

    describe('when the parent is in the cache', () => {
      let before;

      beforeEach(() => {
        cache.writeQuery({ query: workItemByIdQuery, variables, data: parentData.data });
        before = readCounts();
      });

      describe('when a child is closing', () => {
        beforeEach(() => {
          updateCountsForParent({ cache, parentId, workItemType, isClosing: true });
        });

        it('moves one child from opened to closed', () => {
          expect(readCounts().opened).toBe(before.opened - 1);
          expect(readCounts().closed).toBe(before.closed + 1);
        });

        it('leaves the parent query fully readable from the cache', () => {
          expectCacheHit(cache, { query: workItemByIdQuery, variables });
        });
      });

      describe('when a child is reopening', () => {
        beforeEach(() => {
          updateCountsForParent({ cache, parentId, workItemType, isClosing: false });
        });

        it('moves one child from closed to opened', () => {
          expect(readCounts().opened).toBe(before.opened + 1);
          expect(readCounts().closed).toBe(before.closed - 1);
        });
      });
    });

    describe('when the parent is not in the cache', () => {
      it('leaves the cache untouched', () => {
        const before = cache.extract();

        updateCountsForParent({ cache, parentId, workItemType, isClosing: true });

        expect(cache.extract()).toEqual(before);
      });

      it('returns null', () => {
        expect(
          updateCountsForParent({ cache, parentId, workItemType, isClosing: true }),
        ).toBeNull();
      });
    });
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('updateParent on the $path path', ({ useWorkItemFeatures }) => {
    const fullPath = 'gitlab-org';
    const iid = '1';
    const variables = { fullPath, iid, useWorkItemFeatures };

    let removedChild;

    beforeEach(() => {
      window.gon.features = { workItemFeaturesField: useWorkItemFeatures };
    });

    describe('when the parent is in the cache', () => {
      let before;

      beforeEach(() => {
        const parent = workItemByIidResponseFactory({
          hierarchyWidgetPresent: true,
          ...(useWorkItemFeatures ? { features: {} } : {}),
        });
        cache.writeQuery({ query: workItemByIidQuery, variables, data: parent.data });
        before = cache.extract();

        [removedChild] = childrenWorkItems;
        updateParent({ cache, fullPath, iid, workItem: removedChild });
      });

      // `work_item_by_iid` selects no `hierarchy.children` on either path, so there is
      // nothing for updateParent to splice and the read-modify-write round-trips unchanged.
      // Converting or deleting this helper is
      // https://gitlab.com/gitlab-org/gitlab/-/work_items/629621
      it('leaves the cached parent unchanged', () => {
        expect(cache.extract()).toEqual(before);
      });

      it('leaves the parent query fully readable from the cache', () => {
        expectCacheHit(cache, { query: workItemByIidQuery, variables });
      });

      it.todo('removes the child from the parent hierarchy');
    });

    describe('when the parent is not in the cache', () => {
      it('leaves the cache untouched', () => {
        const before = cache.extract();

        updateParent({ cache, fullPath, iid, workItem: { id: 'gid://gitlab/WorkItem/999' } });

        expect(cache.extract()).toEqual(before);
      });
    });
  });

  describe('linkedItems reactive variable in widgets merge', () => {
    const fullPath = 'gitlab-org';
    const iid = '1';
    const key = `${fullPath}:${iid}`;

    const mockLinkedItem = (itemId) => ({
      __typename: 'LinkedWorkItemType',
      linkId: `gid://gitlab/WorkItems::RelatedWorkItemLink/${itemId}`,
      linkType: 'relates_to',
      workItemState: 'OPEN',
      workItem: {
        __typename: 'WorkItem',
        id: `gid://gitlab/WorkItem/${itemId}`,
        iid: `${itemId}`,
        confidential: false,
        namespace: { __typename: 'Namespace', id: 'gid://gitlab/Group/1', fullPath },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/8',
          name: 'Epic',
          iconName: 'work-item-epic',
        },
        title: `Item ${itemId}`,
        titleHtml: `Item ${itemId}`,
        state: 'OPEN',
        createdAt: '2025-01-01T00:00:00Z',
        closedAt: null,
        webUrl: `https://example.com/${itemId}`,
        reference: `${fullPath}#${itemId}`,
      },
    });

    const write = (nodes) => {
      cache.writeQuery({
        query: workItemLinkedItemsSlimQuery,
        variables: { fullPath, iid },
        data: {
          namespace: {
            __typename: 'Namespace',
            id: 'gid://gitlab/Group/1',
            workItem: {
              __typename: 'WorkItem',
              id: 'gid://gitlab/WorkItem/1',
              widgets: [
                {
                  __typename: 'WorkItemWidgetLinkedItems',
                  type: 'LINKED_ITEMS',
                  blockedByCount: 0,
                  blockingCount: 0,
                  linkedItems: { __typename: 'LinkedWorkItemTypeConnection', nodes },
                },
              ],
            },
          },
        },
      });
    };

    it.each`
      description                                                                   | writeNodes                                        | evictKey                               | expectedItems
      ${'populates linkedItems with resolvable items when some are not yet cached'} | ${() => [mockLinkedItem(10), mockLinkedItem(99)]} | ${'WorkItem:gid://gitlab/WorkItem/99'} | ${[{ iid: '10', title: 'Item 10' }]}
      ${'skips items not yet resolvable in cache without silently failing'}         | ${() => [mockLinkedItem(10)]}                     | ${'WorkItem:gid://gitlab/WorkItem/10'} | ${[]}
    `('$description', ({ writeNodes, evictKey, expectedItems }) => {
      write([mockLinkedItem(10)]);

      const originalExtract = cache.extract.bind(cache);
      const spy = jest.spyOn(cache, 'extract');
      spy.mockImplementation(() => {
        const data = originalExtract();
        delete data[evictKey];
        return data;
      });

      try {
        expect(() => write(writeNodes())).not.toThrow();
      } finally {
        spy.mockRestore();
      }

      expect(linkedItems()[key]).toMatchObject(expectedItems);
    });
  });

  describe('reactive variables populated from widgets and features merges', () => {
    const fullPath = 'gitlab-org';
    const iid = '1';
    const workItemId = 'gid://gitlab/WorkItem/1';

    // On the widgets path the factory already provides mockAssignees/mockLabels; on the
    // features path we overlay the same nodes so both paths assert an identical result.
    const writeWorkItem = (useWorkItemFeatures) => {
      const featureDefaults = mockWorkItemFeaturesData();
      const { data } = workItemResponseFactory({
        id: workItemId,
        features: useWorkItemFeatures
          ? {
              assignees: {
                ...featureDefaults.assignees,
                assignees: { __typename: 'UserCoreConnection', nodes: mockAssignees },
              },
              labels: {
                ...featureDefaults.labels,
                labels: { __typename: 'LabelConnection', nodes: mockLabels },
              },
            }
          : null,
      });

      cache.writeQuery({
        query: workItemByIdQuery,
        variables: { id: workItemId, useWorkItemFeatures },
        data,
      });
    };

    const linkedItemNode = {
      __typename: 'LinkedWorkItemType',
      linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/1',
      linkType: 'relates_to',
      workItemState: 'OPEN',
      workItem: {
        __typename: 'WorkItem',
        id: 'gid://gitlab/WorkItem/10',
        iid: '10',
        confidential: false,
        namespace: { __typename: 'Namespace', id: 'gid://gitlab/Group/1', fullPath },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/8',
          name: 'Epic',
          iconName: 'work-item-epic',
        },
        title: 'Item 10',
        titleHtml: 'Item 10',
        state: 'OPEN',
        createdAt: '2025-01-01T00:00:00Z',
        closedAt: null,
        webUrl: 'https://example.com/10',
        reference: `${fullPath}#10`,
      },
    };

    const writeLinkedItems = (useWorkItemFeatures) => {
      const widget = {
        __typename: 'WorkItemWidgetLinkedItems',
        type: 'LINKED_ITEMS',
        blockedByCount: 0,
        blockingCount: 0,
        linkedItems: { __typename: 'LinkedWorkItemTypeConnection', nodes: [linkedItemNode] },
      };

      cache.writeQuery({
        query: workItemLinkedItemsSlimQuery,
        variables: { fullPath, iid, useWorkItemFeatures },
        data: {
          namespace: {
            __typename: 'Namespace',
            id: 'gid://gitlab/Group/1',
            workItem: {
              __typename: 'WorkItem',
              id: workItemId,
              ...(useWorkItemFeatures
                ? {
                    features: {
                      __typename: 'WorkItemFeatures',
                      linkedItems: { ...widget, type: undefined },
                    },
                  }
                : { widgets: [widget] }),
            },
          },
        },
      });
    };

    describe.each`
      path          | useWorkItemFeatures
      ${'widgets'}  | ${false}
      ${'features'} | ${true}
    `('when a work item is written via the $path shape', ({ useWorkItemFeatures }) => {
      beforeEach(() => {
        // Write twice: the widgets merge returns `incoming` early on the first (empty) write.
        writeWorkItem(useWorkItemFeatures);
        writeWorkItem(useWorkItemFeatures);
        writeLinkedItems(useWorkItemFeatures);
        writeLinkedItems(useWorkItemFeatures);
      });

      it('populates the currentAssignees reactive variable', () => {
        expect(currentAssignees()[workItemId]).toMatchObject(
          mockAssignees.map(({ username, avatarUrl }) => ({ username, avatar_url: avatarUrl })),
        );
      });

      it('populates the appliedLabels reactive variable', () => {
        expect(appliedLabels()[workItemId]).toMatchObject(
          mockLabels.map(({ title }) => ({ title })),
        );
      });

      it('populates the linkedItems reactive variable', () => {
        expect(linkedItems()[`${fullPath}:${iid}`]).toMatchObject([
          { iid: '10', title: 'Item 10' },
        ]);
      });
    });

    describe('when an assignee ref is not yet resolvable in the cache', () => {
      const [missingAssignee, resolvableAssignee] = mockAssignees;

      beforeEach(() => {
        // Populate the cache, then evict one assignee so it is missing during extraction.
        writeWorkItem(true);

        const originalExtract = cache.extract.bind(cache);
        jest.spyOn(cache, 'extract').mockImplementation(() => {
          const data = originalExtract();
          delete data[`UserCore:${missingAssignee.id}`];
          return data;
        });
      });

      afterEach(() => {
        cache.extract.mockRestore();
      });

      it('skips the unresolved assignee instead of throwing', () => {
        expect(() => writeWorkItem(true)).not.toThrow();

        expect(currentAssignees()[workItemId]).toMatchObject([
          { username: resolvableAssignee.username },
        ]);
      });
    });
  });
});
