import { GlFormSelect, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WorkItemChangeTypeModal from '~/work_items/components/work_item_change_type_modal.vue';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import convertWorkItemMutation from '~/work_items/graphql/work_item_convert.mutation.graphql';
import getWorkItemDesignListQuery from '~/work_items/components/design_management/graphql/design_collection.query.graphql';
import {
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_TASK,
  WORK_ITEM_WIDGETS_NAME_MAP,
} from '~/work_items/constants';

import {
  convertWorkItemMutationResponse,
  namespaceWorkItemTypesQueryResponse,
  workItemChangeTypeWidgets,
  workItemQueryResponse,
  workItemWithEpicParentQueryResponse,
} from '../mock_data';
import { designCollectionResponse, mockDesign } from './design_management/mock_data';

describe('WorkItemChangeTypeModal component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const typesQuerySuccessHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const issueTypeId = namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes.find(
    (type) => type.name === WORK_ITEM_TYPE_NAME_ISSUE,
  ).id;
  const taskTypeId = namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes.find(
    (type) => type.name === WORK_ITEM_TYPE_NAME_TASK,
  ).id;
  const epicTypeId = namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes.find(
    (item) => item.name === WORK_ITEM_TYPE_NAME_EPIC,
  ).id;

  namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes
    .find((item) => item.name === WORK_ITEM_TYPE_NAME_TASK)
    .widgetDefinitions.splice(
      namespaceWorkItemTypesQueryResponse.data.namespace.workItemTypes.nodes
        .find((item) => item.name === WORK_ITEM_TYPE_NAME_TASK)
        .widgetDefinitions.findIndex((item) => item.type === 'CRM_CONTACTS'),
      1,
    );

  const convertWorkItemMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(convertWorkItemMutationResponse);

  const graphqlError = 'GraphQL error';
  const convertWorkItemMutationErrorResponse = {
    errors: [
      {
        message: graphqlError,
      },
    ],
    data: {
      workItemConvert: null,
    },
  };

  const noDesignQueryHandler = jest.fn().mockResolvedValue(designCollectionResponse([]));
  const oneDesignQueryHandler = jest.fn().mockResolvedValue(designCollectionResponse([mockDesign]));

  const createComponent = ({
    hasParent = false,
    hasChildren = false,
    widgets = [],
    workItemType = WORK_ITEM_TYPE_NAME_TASK,
    namespaceQueryHandler = typesQuerySuccessHandler,
    convertWorkItemMutationHandler = convertWorkItemMutationSuccessHandler,
    designQueryHandler = noDesignQueryHandler,
    hasSubepicsFeature = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemChangeTypeModal, {
      apolloProvider: createMockApollo([
        [namespaceWorkItemTypesQuery, namespaceQueryHandler],
        [convertWorkItemMutation, convertWorkItemMutationHandler],
        [getWorkItemDesignListQuery, designQueryHandler],
      ]),
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        fullPath: 'gitlab-org/gitlab-test',
        workItemIid: '1',
        hasParent,
        hasChildren,
        widgets,
        workItemType,
        allowedChildTypes: [{ name: WORK_ITEM_TYPE_NAME_TASK }],
      },
      provide: {
        hasSubepicsFeature,
        getWorkItemTypeConfiguration: jest.fn(),
      },
    });
  };

  const findChangeTypeModal = () => wrapper.findComponent(GlModal);
  const findGlFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findWarningAlert = () => wrapper.findByTestId('change-type-warning-message');
  const findNoValuePresentAlert = () =>
    wrapper.findByTestId('change-type-no-value-present-message');

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  it('renders change type modal with the select', () => {
    expect(findGlFormSelect().exists()).toBe(true);
    expect(findChangeTypeModal().props('actionPrimary')).toEqual({
      attributes: {
        disabled: true,
        variant: 'confirm',
      },
      text: 'Change type',
    });
  });

  it('calls the `namespaceWorkItemTypesQuery` to get the work item types', () => {
    expect(typesQuerySuccessHandler).toHaveBeenCalled();
  });

  it('renders all types as select options', () => {
    expect(findGlFormSelect().attributes('options').split(',')).toHaveLength(6);
  });

  describe('work item type change tests', () => {
    it.each`
      scenario                                    | widgets                                                      | hasSubepicsFeature | btnDisabled | parentType
      ${'epic parent with subepics enabled'}      | ${workItemWithEpicParentQueryResponse.data.workItem.widgets} | ${true}            | ${false}    | ${''}
      ${'epic parent with subepics disabled'}     | ${workItemWithEpicParentQueryResponse.data.workItem.widgets} | ${false}           | ${true}     | ${'Epic'}
      ${'non-epic parent with subepics enabled'}  | ${workItemQueryResponse.data.workItem.widgets}               | ${true}            | ${true}     | ${'Issue'}
      ${'non-epic parent with subepics disabled'} | ${workItemQueryResponse.data.workItem.widgets}               | ${false}           | ${true}     | ${'Issue'}
    `('$scenario', async ({ widgets, hasSubepicsFeature, btnDisabled, parentType }) => {
      createComponent({
        hasParent: true,
        widgets,
        hasSubepicsFeature,
      });

      await waitForPromises();

      findGlFormSelect().vm.$emit('change', issueTypeId);

      await nextTick();

      const hasWarning = parentType !== '';
      expect(findWarningAlert().exists()).toBe(hasWarning);
      if (hasWarning) {
        const warningText = `Parent item type ${parentType} is not supported on Issue. Remove the parent item to change type.`;
        expect(findWarningAlert().text()).toBe(warningText);
      }
      expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(btnDisabled);
    });
  });

  it('does not allow to change type and disables `Change type` button when the work item has child items', async () => {
    createComponent({ workItemType: WORK_ITEM_TYPE_NAME_ISSUE, hasChildren: true });

    await waitForPromises();

    findGlFormSelect().vm.$emit('change', taskTypeId);

    await nextTick();

    expect(findWarningAlert().text()).toBe(
      'Task does not support the Task child item types. Remove child items to change type.',
    );
    expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(true);
  });

  describe('when widget data has difference', () => {
    it('shows warning message in case of designs', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        designQueryHandler: oneDesignQueryHandler,
      });

      await waitForPromises();

      findGlFormSelect().vm.$emit('change', taskTypeId);

      await nextTick();

      expect(findWarningAlert().text()).toContain('Design');
      expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(false);
    });

    it('shows warning message in case of Contacts widget', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        widgets: [workItemChangeTypeWidgets.CRM_CONTACTS],
      });

      await waitForPromises();

      findGlFormSelect().vm.$emit('change', taskTypeId);

      await nextTick();

      expect(findWarningAlert().text()).toContain('Contacts');
      expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(false);
    });

    it.each`
      widgetType                              | widgetData                             | workItemType                 | typeTobeConverted | expectedString
      ${WORK_ITEM_WIDGETS_NAME_MAP.ITERATION} | ${workItemChangeTypeWidgets.ITERATION} | ${WORK_ITEM_TYPE_NAME_ISSUE} | ${epicTypeId}     | ${'Iteration'}
      ${WORK_ITEM_WIDGETS_NAME_MAP.WEIGHT}    | ${workItemChangeTypeWidgets.WEIGHT}    | ${WORK_ITEM_TYPE_NAME_ISSUE} | ${epicTypeId}     | ${'Weight'}
    `(
      'shows warning message in case of $widgetType widget',
      async ({ workItemType, widgetData, typeTobeConverted, expectedString }) => {
        createComponent({
          workItemType,
          widgets: [widgetData],
        });

        await waitForPromises();

        findGlFormSelect().vm.$emit('change', typeTobeConverted);

        await nextTick();

        expect(findWarningAlert().text()).toContain(expectedString);
        expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(false);
      },
    );

    it('shows no value present message if value of the widget is not present on conversion', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_NAME_ISSUE,
        widgets: [workItemChangeTypeWidgets.MILESTONE],
      });

      await waitForPromises();

      findGlFormSelect().vm.$emit('change', epicTypeId);

      await nextTick();

      expect(findNoValuePresentAlert().text()).toContain('Milestone: v4.0');
    });
  });

  describe('convert work item mutation', () => {
    it('successfully changes a work item type when conditions are met', async () => {
      createComponent();

      await waitForPromises();

      findGlFormSelect().vm.$emit('change', issueTypeId);

      await nextTick();

      findChangeTypeModal().vm.$emit('primary');

      await waitForPromises();

      expect(convertWorkItemMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          workItemTypeId: issueTypeId,
        },
        useWorkItemFeatures: false,
      });
    });

    it.each`
      errorType          | expectedErrorMessage | failureHandler
      ${'graphql error'} | ${graphqlError}      | ${jest.fn().mockResolvedValue(convertWorkItemMutationErrorResponse)}
      ${'network error'} | ${'Network error'}   | ${jest.fn().mockRejectedValue(new Error('Network error'))}
    `(
      'emits an error when there is a $errorType',
      async ({ expectedErrorMessage, failureHandler }) => {
        createComponent({
          convertWorkItemMutationHandler: failureHandler,
        });

        await waitForPromises();

        findGlFormSelect().vm.$emit('change', issueTypeId);

        await nextTick();

        findChangeTypeModal().vm.$emit('primary');

        await waitForPromises();

        expect(wrapper.emitted('error')[0][0]).toEqual(expectedErrorMessage);
      },
    );
  });
});
