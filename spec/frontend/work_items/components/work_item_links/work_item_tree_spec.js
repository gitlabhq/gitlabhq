import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlToggle, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';
import WorkItemTreeActions from '~/work_items/components/work_item_links/work_item_tree_actions.vue';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_VALUE_EPIC,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
} from '~/work_items/constants';
import {
  workItemHierarchyTreeResponse,
  workItemHierarchyPaginatedTreeResponse,
  workItemHierarchyTreeEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemTree', () => {
  let wrapper;

  const workItemHierarchyTreeResponseHandler = jest
    .fn()
    .mockResolvedValue(workItemHierarchyTreeResponse);

  const findEmptyState = () => wrapper.findByTestId('tree-empty');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findToggleFormSplitButton = () => wrapper.findComponent(WorkItemActionsSplitButton);
  const findForm = () => wrapper.findComponent(WorkItemLinksForm);
  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findWorkItemLinkChildrenWrapper = () => wrapper.findComponent(WorkItemChildrenWrapper);
  const findShowLabelsToggle = () => wrapper.findComponent(GlToggle);
  const findTreeActions = () => wrapper.findComponent(WorkItemTreeActions);
  const findRolledUpWeight = () => wrapper.findByTestId('rollup-weight');
  const findRolledUpWeightValue = () => wrapper.findByTestId('weight-value');

  const createComponent = async ({
    workItemType = 'Objective',
    workItemIid = '2',
    parentWorkItemType = 'Objective',
    confidential = false,
    canUpdate = true,
    canUpdateChildren = true,
    hasSubepicsFeature = true,
    workItemHierarchyTreeHandler = workItemHierarchyTreeResponseHandler,
    showRolledUpWeight = false,
    rolledUpWeight = 0,
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
        showRolledUpWeight,
        rolledUpWeight,
      },
      apolloProvider: createMockApollo([[getWorkItemTreeQuery, workItemHierarchyTreeHandler]]),
      provide: {
        hasSubepicsFeature,
      },
      stubs: { WidgetWrapper },
    });
    await waitForPromises();
  };

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

  it('does not display form by default', () => {
    createComponent();

    expect(findForm().exists()).toBe(false);
  });

  it('shows an error message on error', async () => {
    const errorMessage = 'Some error';
    await createComponent();

    findWorkItemLinkChildrenWrapper().vm.$emit('error', errorMessage);
    await nextTick();

    expect(findWidgetWrapper().props('error')).toBe(errorMessage);
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

    it('does not display link menu on children', () => {
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

  it.each`
    toggleValue
    ${true}
    ${false}
  `(
    'passes showLabels as $toggleValue to child items when toggle is $toggleValue',
    async ({ toggleValue }) => {
      await createComponent();

      findShowLabelsToggle().vm.$emit('change', toggleValue);

      await nextTick();

      expect(findWorkItemLinkChildrenWrapper().props('showLabels')).toBe(toggleValue);
    },
  );

  describe('action menu', () => {
    it.each`
      visible  | workItemType
      ${true}  | ${WORK_ITEM_TYPE_VALUE_EPIC}
      ${false} | ${WORK_ITEM_TYPE_VALUE_OBJECTIVE}
    `(
      'When displaying a $workItemType, it is $visible that the action menu is rendered',
      async ({ workItemType, visible }) => {
        await createComponent({ workItemType });

        expect(findTreeActions().exists()).toBe(visible);
      },
    );
  });

  describe('rollup data', () => {
    describe('rolledUp weight', () => {
      it.each`
        showRolledUpWeight | rolledUpWeight | expected
        ${false}           | ${0}           | ${'rollup weight is not displayed'}
        ${false}           | ${10}          | ${'rollup weight is not displayed'}
        ${true}            | ${0}           | ${'rollup weight is displayed'}
        ${true}            | ${10}          | ${'rollup weight is displayed'}
      `(
        'When showRolledUpWeight is $showRolledUpWeight and rolledUpWeight is $rolledUpWeight, $expected',
        ({ showRolledUpWeight, rolledUpWeight }) => {
          createComponent({ showRolledUpWeight, rolledUpWeight });

          expect(findRolledUpWeight().exists()).toBe(showRolledUpWeight);
        },
      );

      it('should show the correct value when rolledUpWeight is visible', () => {
        createComponent({ showRolledUpWeight: true, rolledUpWeight: 10 });

        expect(findRolledUpWeight().exists()).toBe(true);
        expect(findRolledUpWeight().findComponent(GlIcon).props('name')).toBe('weight');
        expect(findRolledUpWeightValue().text()).toBe('10');
      });
    });
  });
});
