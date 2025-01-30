import { GlModal, GlFormSelect } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

import WorkItemChangeTypeModal from '~/work_items/components/work_item_change_type_modal.vue';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import convertWorkItemMutation from '~/work_items/graphql/work_item_convert.mutation.graphql';
import getWorkItemDesignListQuery from '~/work_items/components/design_management/graphql/design_collection.query.graphql';
import { WORK_ITEM_TYPE_VALUE_TASK, WORK_ITEM_TYPE_VALUE_ISSUE } from '~/work_items/constants';

import {
  convertWorkItemMutationResponse,
  workItemChangeTypeWidgets,
  workItemQueryResponse,
} from '../mock_data';
import { designCollectionResponse, mockDesign } from './design_management/mock_data';

describe('WorkItemChangeTypeModal component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const typesQuerySuccessHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const issueTypeId = namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.find(
    (type) => type.name === WORK_ITEM_TYPE_VALUE_ISSUE,
  ).id;
  const taskTypeId = namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.find(
    (type) => type.name === WORK_ITEM_TYPE_VALUE_TASK,
  ).id;
  namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes
    .find((item) => item.name === WORK_ITEM_TYPE_VALUE_TASK)
    .widgetDefinitions.splice(
      namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes
        .find((item) => item.name === WORK_ITEM_TYPE_VALUE_TASK)
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
    workItemType = WORK_ITEM_TYPE_VALUE_TASK,
    convertWorkItemMutationHandler = convertWorkItemMutationSuccessHandler,
    designQueryHandler = noDesignQueryHandler,
  } = {}) => {
    wrapper = mountExtended(WorkItemChangeTypeModal, {
      apolloProvider: createMockApollo([
        [namespaceWorkItemTypesQuery, typesQuerySuccessHandler],
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
        allowedChildTypes: [{ name: WORK_ITEM_TYPE_VALUE_TASK }],
        allowedWorkItemTypesEE: [],
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  };

  const findChangeTypeModal = () => wrapper.findComponent(GlModal);
  const findGlFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findWarningAlert = () => wrapper.findByTestId('change-type-warning-message');

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  it('renders change type modal with the select', () => {
    expect(findChangeTypeModal().exists()).toBe(true);
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
    expect(findGlFormSelect().findAll('option')).toHaveLength(2);
  });

  it('does not allow to change type and disables `Change type` button when the work item has a parent', async () => {
    createComponent({ hasParent: true, widgets: workItemQueryResponse.data.workItem.widgets });

    await waitForPromises();

    findGlFormSelect().vm.$emit('change', issueTypeId);

    await nextTick();

    expect(findWarningAlert().text()).toBe(
      'Parent item type issue is not supported on issue. Remove the parent item to change type.',
    );

    expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(true);
  });

  it('does not allow to change type and disables `Change type` button when the work item has child items', async () => {
    createComponent({ workItemType: WORK_ITEM_TYPE_VALUE_ISSUE, hasChildren: true });

    await waitForPromises();

    findGlFormSelect().vm.$emit('change', taskTypeId);

    await nextTick();

    expect(findWarningAlert().text()).toBe(
      'Task does not support the task child item types. Remove child items to change type.',
    );
    expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(true);
  });

  describe('when widget data has difference', () => {
    it('shows warning message in case of designs', async () => {
      createComponent({
        workItemType: WORK_ITEM_TYPE_VALUE_ISSUE,
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
        workItemType: WORK_ITEM_TYPE_VALUE_ISSUE,
        widgets: [workItemChangeTypeWidgets.CRM_CONTACTS],
      });

      await waitForPromises();

      findGlFormSelect().vm.$emit('change', taskTypeId);

      await nextTick();

      expect(findWarningAlert().text()).toContain('Contacts');
      expect(findChangeTypeModal().props('actionPrimary').attributes.disabled).toBe(false);
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
