import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { createAlert } from '~/alert';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';
import WorkItemMoreActions from '~/work_items/components/shared/work_item_more_actions.vue';
import WorkItemToggleClosedItems from '~/work_items/components/shared/work_item_toggle_closed_items.vue';
import WorkItemRolledUpData from '~/work_items/components/work_item_links/work_item_rolled_up_data.vue';
import WorkItemRolledUpCount from '~/work_items/components/work_item_links/work_item_rolled_up_count.vue';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_VALUE_EPIC,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_TASK,
  WORKITEM_TREE_SHOWLABELS_LOCALSTORAGEKEY,
  WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY,
} from '~/work_items/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import * as utils from '~/work_items/utils';
import {
  workItemHierarchyTreeResponse,
  workItemHierarchyPaginatedTreeResponse,
  workItemHierarchyTreeEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  workItemHierarchyTreeSingleClosedItemResponse,
  mockRolledUpCountsByType,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemTree', () => {
  let wrapper;

  const workItemHierarchyTreeResponseHandler = jest
    .fn()
    .mockResolvedValue(workItemHierarchyTreeResponse);
  const namespaceWorkItemTypesQueryHandler = jest
    .fn()
    .mockResolvedValue(namespaceWorkItemTypesQueryResponse);

  const findEmptyState = () => wrapper.findByTestId('crud-empty');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findToggleFormSplitButton = () => wrapper.findComponent(WorkItemActionsSplitButton);
  const findForm = () => wrapper.findComponent(WorkItemLinksForm);
  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findWorkItemLinkChildrenWrapper = () => wrapper.findComponent(WorkItemChildrenWrapper);
  const findMoreActions = () => wrapper.findComponent(WorkItemMoreActions);
  const findShowClosedButton = () => wrapper.findComponent(WorkItemToggleClosedItems);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findRolledUpData = () => wrapper.findComponent(WorkItemRolledUpData);
  const findRolledUpCount = () => wrapper.findComponent(WorkItemRolledUpCount);

  const createComponent = async ({
    workItemType = 'Objective',
    workItemIid = '2',
    parentWorkItemType = 'Objective',
    confidential = false,
    canUpdate = true,
    canUpdateChildren = true,
    hasSubepicsFeature = true,
    workItemHierarchyTreeHandler = workItemHierarchyTreeResponseHandler,
    shouldWaitForPromise = true,
    closedChildrenCount = 0,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemTree, {
      propsData: {
        fullPath: 'test/project',
        workItemType,
        workItemIid,
        parentWorkItemType,
        workItemId: 'gid://gitlab/WorkItem/2',
        confidential,
        canUpdate,
        canUpdateChildren,
      },
      apolloProvider: createMockApollo([
        [getWorkItemTreeQuery, workItemHierarchyTreeHandler],
        [namespaceWorkItemTypesQuery, namespaceWorkItemTypesQueryHandler],
      ]),
      provide: {
        hasSubepicsFeature,
        closedChildrenCount,
      },
      stubs: { CrudComponent },
    });

    if (shouldWaitForPromise) {
      await waitForPromises();
    }
  };

  beforeEach(() => {
    utils.saveToggleToLocalStorage(WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY, true);
  });

  it('displays Add button', () => {
    createComponent();

    expect(findToggleFormSplitButton().exists()).toBe(true);
  });

  it('displays empty state if there are no children', async () => {
    await createComponent({
      workItemHierarchyTreeHandler: jest.fn().mockResolvedValue(workItemHierarchyTreeEmptyResponse),
    });

    expect(findEmptyState().exists()).toBe(true);
  });

  it('displays loading-icon while children are being loaded', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders hierarchy widget children container', async () => {
    await createComponent();

    expect(findWorkItemLinkChildrenWrapper().exists()).toBe(true);
    expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(1);
  });

  it.each`
    workItemType                      | showTaskWeight
    ${WORK_ITEM_TYPE_VALUE_EPIC}      | ${false}
    ${WORK_ITEM_TYPE_VALUE_TASK}      | ${true}
    ${WORK_ITEM_TYPE_VALUE_OBJECTIVE} | ${true}
  `(
    'passes `showTaskWeight` as $showTaskWeight when the type is $workItemType',
    async ({ workItemType, showTaskWeight }) => {
      await createComponent({ workItemType });

      expect(findWorkItemLinkChildrenWrapper().props().showTaskWeight).toBe(showTaskWeight);
    },
  );

  it('does not display form by default', () => {
    createComponent();

    expect(findForm().exists()).toBe(false);
  });

  it('shows an error message on error', async () => {
    const errorMessage = 'Some error';
    await createComponent();

    findWorkItemLinkChildrenWrapper().vm.$emit('error', errorMessage);
    await nextTick();

    expect(findErrorMessage().text()).toBe(errorMessage);
  });

  it.each`
    option                   | formType             | childType
    ${'New objective'}       | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${'Existing objective'}  | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${'New key result'}      | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
    ${'Existing key result'} | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
  `(
    'when triggering action $option, renders the form passing $formType and $childType',
    async ({ formType, childType }) => {
      createComponent();

      wrapper.vm.showAddForm(formType, childType);
      await nextTick();

      expect(findForm().exists()).toBe(true);
      expect(findForm().props()).toMatchObject({
        formType,
        childrenType: childType,
        parentWorkItemType: 'Objective',
        parentConfidential: false,
      });
    },
  );

  describe('when subepics are not available', () => {
    it.each`
      option              | formType             | childType
      ${'New issue'}      | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_ISSUE}
      ${'Existing issue'} | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_ISSUE}
    `(
      'when triggering action $option, renders the form passing $formType and $childType',
      async ({ formType, childType }) => {
        createComponent({ hasSubepicsFeature: false, workItemType: 'Epic' });

        wrapper.vm.showAddForm(formType, childType);
        await nextTick();

        expect(findForm().exists()).toBe(true);
        expect(findForm().props()).toMatchObject({
          formType,
          childrenType: childType,
        });
      },
    );
  });

  describe('when subepics are available', () => {
    it.each`
      option              | formType             | childType
      ${'New issue'}      | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_ISSUE}
      ${'Existing issue'} | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_ISSUE}
      ${'New epic'}       | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_EPIC}
      ${'Existing epic'}  | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_EPIC}
    `(
      'when triggering action $option, renders the form passing $formType and $childType',
      async ({ formType, childType }) => {
        createComponent({ hasSubepicsFeature: true, workItemType: 'Epic' });

        wrapper.vm.showAddForm(formType, childType);
        await nextTick();

        expect(findForm().exists()).toBe(true);
        expect(findForm().props()).toMatchObject({
          formType,
          childrenType: childType,
        });
      },
    );
  });

  describe('when no permission to update', () => {
    beforeEach(async () => {
      await createComponent({
        canUpdate: false,
        canUpdateChildren: false,
        workItemHierarchyTreeHandler: jest
          .fn()
          .mockResolvedValue(workItemHierarchyNoUpdatePermissionResponse),
      });
    });

    it('does not display button to toggle Add form', () => {
      expect(findToggleFormSplitButton().exists()).toBe(false);
    });

    it('passes correct `canUpdate` prop to children wrapper', () => {
      expect(findWorkItemLinkChildrenWrapper().props('canUpdate')).toBe(false);
    });
  });

  describe('pagination', () => {
    const findWorkItemChildrenLoadMore = () => wrapper.findByTestId('work-item-load-more');
    let workItemTreeQueryHandler;

    beforeEach(async () => {
      workItemTreeQueryHandler = jest
        .fn()
        .mockResolvedValue(workItemHierarchyPaginatedTreeResponse);

      await createComponent({
        workItemHierarchyTreeHandler: workItemTreeQueryHandler,
      });
    });

    it('shows work-item-children-load-more component when hasNextPage is true and node is expanded', () => {
      const loadMore = findWorkItemChildrenLoadMore();
      expect(loadMore.exists()).toBe(true);
      expect(loadMore.props('fetchNextPageInProgress')).toBe(false);
    });

    it('does not render the `work-item-toggle-closed-items` component when hasNextPage is true', () => {
      expect(findShowClosedButton().exists()).toBe(false);
    });

    it('queries next page children when work-item-children-load-more emits "fetch-next-page"', async () => {
      findWorkItemChildrenLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(workItemTreeQueryHandler).toHaveBeenCalled();
    });

    it('shows alert message when fetching next page fails', async () => {
      jest.spyOn(wrapper.vm.$apollo.queries.hierarchyWidget, 'fetchMore').mockRejectedValueOnce({});
      findWorkItemChildrenLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while fetching children.',
      });
    });
  });

  it('emits `addChild` event when form emits `addChild` event', async () => {
    createComponent();

    wrapper.vm.showAddForm(FORM_TYPES.create, WORK_ITEM_TYPE_ENUM_OBJECTIVE);
    await nextTick();
    findForm().vm.$emit('addChild');

    expect(wrapper.emitted('addChild')).toEqual([[]]);
  });

  describe('more actions', () => {
    useLocalStorageSpy();

    beforeEach(async () => {
      jest.spyOn(utils, 'getToggleFromLocalStorage');
      jest.spyOn(utils, 'saveToggleToLocalStorage');
      await createComponent();
    });

    afterEach(() => {
      localStorage.clear();
    });

    it.each`
      visible | workItemType
      ${true} | ${WORK_ITEM_TYPE_VALUE_EPIC}
      ${true} | ${WORK_ITEM_TYPE_VALUE_OBJECTIVE}
    `('renders when the work item type is $workItemType', async ({ workItemType, visible }) => {
      await createComponent({ workItemType });

      expect(findMoreActions().exists()).toBe(visible);
    });

    it('renders `View on a roadmap` action', async () => {
      await createComponent();

      expect(findMoreActions().props('showViewRoadmapAction')).toBe(true);
    });

    it.each`
      toggleName      | toggleEvent
      ${'showLabels'} | ${'toggle-show-labels'}
      ${'showClosed'} | ${'toggle-show-closed'}
    `(
      'toggles `$toggleName` when `$toggleEvent` is emitted',
      async ({ toggleName, toggleEvent }) => {
        await createComponent();

        expect(findMoreActions().props(toggleName)).toBe(true);

        await findMoreActions().vm.$emit(toggleEvent);

        expect(findMoreActions().props(toggleName)).toBe(false);

        await findMoreActions().vm.$emit(toggleEvent);

        expect(findMoreActions().props(toggleName)).toBe(true);
      },
    );

    it('calls saveToggleToLocalStorage on toggle', () => {
      findMoreActions().vm.$emit('toggle-show-labels');
      expect(utils.saveToggleToLocalStorage).toHaveBeenCalled();
    });

    it('calls saveToggleToLocalStorage on toggle-show-closed', () => {
      findMoreActions().vm.$emit('toggle-show-closed');
      expect(utils.saveToggleToLocalStorage).toHaveBeenCalled();
    });

    it('calls getToggleFromLocalStorage on mount for showClosed', () => {
      expect(utils.getToggleFromLocalStorage).toHaveBeenCalledWith(
        WORKITEM_TREE_SHOWLABELS_LOCALSTORAGEKEY,
      );
    });

    it('calls getToggleFromLocalStorage on mount for showLabels', () => {
      expect(utils.getToggleFromLocalStorage).toHaveBeenCalledWith(
        WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY,
      );
    });
  });

  it('renders crud component', async () => {
    await createComponent();

    expect(findCrudComponent().exists()).toBe(true);
  });

  it('renders rolled up data only when query is loaded', async () => {
    createComponent({ shouldWaitForPromise: false });

    expect(findRolledUpData().exists()).toBe(false);
    expect(findRolledUpCount().exists()).toBe(false);

    await waitForPromises();

    expect(findRolledUpData().exists()).toBe(true);
    expect(findRolledUpCount().exists()).toBe(true);

    expect(findRolledUpData().props()).toEqual({
      workItemId: 'gid://gitlab/WorkItem/2',
      workItemIid: '2',
      workItemType: 'Objective',
      fullPath: 'test/project',
    });

    expect(findRolledUpCount().props()).toEqual({
      hideCountWhenZero: false,
      infoType: 'badge',
      rolledUpCountsByType: mockRolledUpCountsByType,
    });
  });

  it('fetches widget definitions and passes formatted allowed children by type to children wrapper', async () => {
    await createComponent();

    expect(namespaceWorkItemTypesQueryHandler).toHaveBeenCalled();
    await nextTick();

    expect(findWorkItemLinkChildrenWrapper().props('allowedChildrenByType')).toEqual({
      Epic: ['Epic', 'Issue'],
      Incident: ['Task'],
      Issue: ['Task'],
      Objective: ['Key Result', 'Objective'],
      Ticket: ['Task'],
    });
  });

  describe('work item show closed button', () => {
    beforeEach(async () => {
      await createComponent({
        workItemHierarchyTreeHandler: jest
          .fn()
          .mockResolvedValue(workItemHierarchyTreeSingleClosedItemResponse),
      });
      await findMoreActions().vm.$emit('toggle-show-closed');
    });

    it('displays show closed button', () => {
      expect(findShowClosedButton().exists()).toBe(true);
    });

    it('shows the closed item when the show closed button is clicked', async () => {
      await findShowClosedButton().vm.$emit('show-closed');

      expect(findShowClosedButton().exists()).toBe(false);

      expect(wrapper.findByTestId('work-item-no-child-items-open').exists()).toBe(false);
    });
  });

  it('displays no child items open message', async () => {
    await createComponent({
      workItemHierarchyTreeHandler: jest
        .fn()
        .mockResolvedValue(workItemHierarchyTreeSingleClosedItemResponse),
    });

    expect(wrapper.findByTestId('work-item-no-child-items-open').exists()).toBe(false);

    await findMoreActions().vm.$emit('toggle-show-closed');

    expect(wrapper.findByTestId('work-item-no-child-items-open').text()).toBe(
      'No child items are currently open.',
    );

    expect(findShowClosedButton().exists()).toBe(true);
  });

  describe('when there is show URL parameter', () => {
    it('emits `show-modal` event when child work item id is encoded in the URL', async () => {
      const encodedWorkItemId = btoa(JSON.stringify({ id: 31 }));
      setWindowLocation(`?show=${encodedWorkItemId}`);
      await createComponent();

      expect(wrapper.emitted('show-modal')).toEqual([
        [{ modalWorkItem: expect.objectContaining({ id: 'gid://gitlab/WorkItem/31' }) }],
      ]);
    });

    it('does not emit `show-modal` event when child work item id is not encoded in the URL', async () => {
      const encodedWorkItemId = btoa(JSON.stringify({ id: 1 }));
      setWindowLocation(`?show=${encodedWorkItemId}`);
      await createComponent();

      expect(wrapper.emitted('show-modal')).toBeUndefined();
    });
  });
});
