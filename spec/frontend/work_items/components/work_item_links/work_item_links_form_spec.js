import Vue from 'vue';
import { GlForm, GlFormInput, GlFormCheckbox, GlTooltip, GlTokenSelector } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { sprintf, s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL,
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP,
} from '~/work_items/constants';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import {
  availableWorkItemsResponse,
  projectWorkItemTypesQueryResponse,
  createWorkItemMutationResponse,
  updateWorkItemMutationResponse,
  mockIterationWidgetResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemLinksForm', () => {
  let wrapper;

  const updateMutationResolver = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const createMutationResolver = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const availableWorkItemsResolver = jest.fn().mockResolvedValue(availableWorkItemsResponse);

  const mockParentIteration = mockIterationWidgetResponse;

  const createComponent = async ({
    typesResponse = projectWorkItemTypesQueryResponse,
    parentConfidential = false,
    hasIterationsFeature = false,
    parentIteration = null,
    formType = FORM_TYPES.create,
    parentWorkItemType = WORK_ITEM_TYPE_VALUE_ISSUE,
    childrenType = WORK_ITEM_TYPE_ENUM_TASK,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, availableWorkItemsResolver],
        [projectWorkItemTypesQuery, jest.fn().mockResolvedValue(typesResponse)],
        [updateWorkItemMutation, updateMutationResolver],
        [createWorkItemMutation, createMutationResolver],
      ]),
      propsData: {
        issuableGid: 'gid://gitlab/WorkItem/1',
        parentConfidential,
        parentIteration,
        parentWorkItemType,
        childrenType,
        formType,
      },
      provide: {
        projectPath: 'project/path',
        hasIterationsFeature,
      },
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findConfidentialCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findAddChildButton = () => wrapper.findByTestId('add-child-button');

  describe('creating a new work item', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders create form', () => {
      expect(findForm().exists()).toBe(true);
      expect(findInput().exists()).toBe(true);
      expect(findAddChildButton().text()).toBe('Create task');
      expect(findTokenSelector().exists()).toBe(false);
    });

    it('creates child task in non confidential parent', async () => {
      findInput().vm.$emit('input', 'Create task test');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(wrapper.vm.childWorkItemType).toEqual('gid://gitlab/WorkItems::Type/3');
      expect(createMutationResolver).toHaveBeenCalledWith({
        input: {
          title: 'Create task test',
          projectPath: 'project/path',
          workItemTypeId: 'gid://gitlab/WorkItems::Type/3',
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/1',
          },
          confidential: false,
        },
      });
    });

    it('creates child task in confidential parent', async () => {
      await createComponent({ parentConfidential: true });

      findInput().vm.$emit('input', 'Create confidential task');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(wrapper.vm.childWorkItemType).toEqual('gid://gitlab/WorkItems::Type/3');
      expect(createMutationResolver).toHaveBeenCalledWith({
        input: {
          title: 'Create confidential task',
          projectPath: 'project/path',
          workItemTypeId: 'gid://gitlab/WorkItems::Type/3',
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/1',
          },
          confidential: true,
        },
      });
    });

    describe('confidentiality checkbox', () => {
      it('renders confidentiality checkbox', () => {
        const confidentialCheckbox = findConfidentialCheckbox();

        expect(confidentialCheckbox.exists()).toBe(true);
        expect(wrapper.findComponent(GlTooltip).exists()).toBe(false);
        expect(confidentialCheckbox.text()).toBe(
          sprintf(I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL, {
            workItemType: WORK_ITEM_TYPE_ENUM_TASK.toLocaleLowerCase(),
          }),
        );
      });

      it('renders confidentiality tooltip with checkbox checked and disabled when parent is confidential', () => {
        createComponent({ parentConfidential: true });

        const confidentialCheckbox = findConfidentialCheckbox();
        const confidentialTooltip = wrapper.findComponent(GlTooltip);

        expect(confidentialCheckbox.attributes('disabled')).toBeDefined();
        expect(confidentialCheckbox.attributes('checked')).toBe('true');
        expect(confidentialTooltip.exists()).toBe(true);
        expect(confidentialTooltip.text()).toBe(
          sprintf(I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP, {
            workItemType: WORK_ITEM_TYPE_ENUM_TASK.toLocaleLowerCase(),
            parentWorkItemType: WORK_ITEM_TYPE_VALUE_ISSUE.toLocaleLowerCase(),
          }),
        );
      });
    });
  });

  describe('adding an existing work item', () => {
    const selectAvailableWorkItemTokens = async () => {
      findTokenSelector().vm.$emit(
        'input',
        availableWorkItemsResponse.data.workspace.workItems.nodes,
      );
      findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));

      await waitForPromises();
    };

    beforeEach(async () => {
      await createComponent({ formType: FORM_TYPES.add });
    });

    it('renders add form', () => {
      expect(findForm().exists()).toBe(true);
      expect(findTokenSelector().exists()).toBe(true);
      expect(findAddChildButton().text()).toBe('Add task');
      expect(findInput().exists()).toBe(false);
      expect(findConfidentialCheckbox().exists()).toBe(false);
    });

    it('searches for available work items as prop when typing in input', async () => {
      findTokenSelector().vm.$emit('focus');
      findTokenSelector().vm.$emit('text-input', 'Task');
      await waitForPromises();

      expect(availableWorkItemsResolver).toHaveBeenCalled();
    });

    it('selects and adds children', async () => {
      await selectAvailableWorkItemTokens();

      expect(findAddChildButton().text()).toBe('Add tasks');
      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(updateMutationResolver).toHaveBeenCalled();
    });

    it('shows validation error when non-confidential child items are being added to confidential parent', async () => {
      await createComponent({ formType: FORM_TYPES.add, parentConfidential: true });

      await selectAvailableWorkItemTokens();

      const validationEl = wrapper.findByTestId('work-items-invalid');
      expect(validationEl.exists()).toBe(true);
      expect(validationEl.text().trim()).toBe(
        sprintf(
          s__(
            'WorkItem|%{invalidWorkItemsList} cannot be added: Cannot assign a non-confidential %{childWorkItemType} to a confidential parent %{parentWorkItemType}. Make the selected %{childWorkItemType} confidential and try again.',
          ),
          {
            // Only non-confidential work items are shown in the error message
            invalidWorkItemsList: availableWorkItemsResponse.data.workspace.workItems.nodes
              .filter((wi) => !wi.confidential)
              .map((wi) => wi.title)
              .join(', '),
            childWorkItemType: 'Task',
            parentWorkItemType: 'Issue',
          },
        ),
      );
    });
  });

  describe('associate iteration with task', () => {
    it('updates when parent has an iteration associated', async () => {
      await createComponent({
        hasIterationsFeature: true,
        parentIteration: mockParentIteration,
      });
      findInput().vm.$emit('input', 'Create task test');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(createMutationResolver).toHaveBeenCalledWith({
        input: {
          title: 'Create task test',
          projectPath: 'project/path',
          workItemTypeId: 'gid://gitlab/WorkItems::Type/3',
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/1',
          },
          confidential: false,
          iterationWidget: {
            iterationId: mockParentIteration.id,
          },
        },
      });
    });
    it('does not send the iteration widget to mutation when parent has no iteration associated', async () => {
      await createComponent({
        hasIterationsFeature: true,
      });
      findInput().vm.$emit('input', 'Create task test');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(createMutationResolver).not.toHaveBeenCalledWith({
        input: {
          title: 'Create task test',
          projectPath: 'project/path',
          workItemTypeId: 'gid://gitlab/WorkItems::Type/3',
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/1',
          },
          confidential: false,
          iterationWidget: {
            iterationId: mockParentIteration.id,
          },
        },
      });
    });
  });
});
