import Vue, { nextTick } from 'vue';
import { GlForm, GlFormGroup, GlFormInput, GlFormCheckbox, GlTooltip } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';
import { sprintf, s__ } from '~/locale';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import WorkItemProjectsListbox from '~/work_items/components/work_item_links/work_item_projects_listbox.vue';
import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_VALUE_EPIC,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL,
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP,
  SEARCH_DEBOUNCE,
  WORK_ITEM_TYPE_ENUM_EPIC,
} from '~/work_items/constants';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateWorkItemHierarchyMutation from '~/work_items/graphql/update_work_item_hierarchy.mutation.graphql';
import namespaceProjectsForLinksWidgetQuery from '~/work_items/graphql/namespace_projects_for_links_widget.query.graphql';
import {
  availableWorkItemsResponse,
  createWorkItemMutationResponse,
  updateWorkItemMutationResponse,
  mockIterationWidgetResponse,
  namespaceProjectsList,
} from '../../mock_data';

Vue.use(VueApollo);

const projectData = namespaceProjectsList.data.namespace.projects.nodes;

const findWorkItemTypeId = (typeName) => {
  return namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.find(
    (node) => node.name === typeName,
  ).id;
};

const workItemTypeIdForTask = findWorkItemTypeId('Task');
const workItemTypeIdForIssue = findWorkItemTypeId('Issue');
const workItemTypeIdForEpic = findWorkItemTypeId('Epic');

describe('WorkItemLinksForm', () => {
  /**
   * @type {import('helpers/vue_test_utils_helper').ExtendedWrapper}
   */
  let wrapper;

  const updateMutationResolver = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const updateMutationRejection = jest.fn().mockRejectedValue(new Error('error'));
  const createMutationResolver = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const createMutationRejection = jest.fn().mockRejectedValue(new Error('error'));
  const availableWorkItemsResolver = jest.fn().mockResolvedValue(availableWorkItemsResponse);
  const namespaceWorkItemTypesResolver = jest
    .fn()
    .mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const namespaceProjectsFormLinksWidgetResolver = jest
    .fn()
    .mockResolvedValue(namespaceProjectsList);

  const mockParentIteration = mockIterationWidgetResponse;

  const createComponent = async ({
    parentConfidential = false,
    hasIterationsFeature = false,
    parentIteration = null,
    formType = FORM_TYPES.create,
    parentWorkItemType = WORK_ITEM_TYPE_VALUE_ISSUE,
    childrenType = WORK_ITEM_TYPE_ENUM_TASK,
    updateMutation = updateMutationResolver,
    createMutation = createMutationResolver,
    isGroup = false,
    createGroupLevelWorkItems = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, availableWorkItemsResolver],
        [namespaceWorkItemTypesQuery, namespaceWorkItemTypesResolver],
        [namespaceProjectsForLinksWidgetQuery, namespaceProjectsFormLinksWidgetResolver],
        [updateWorkItemHierarchyMutation, updateMutation],
        [createWorkItemMutation, createMutation],
      ]),
      propsData: {
        fullPath: 'group-a',
        issuableGid: 'gid://gitlab/WorkItem/1',
        parentConfidential,
        parentIteration,
        parentWorkItemType,
        childrenType,
        formType,
        glFeatures: {
          createGroupLevelWorkItems,
        },
      },
      provide: {
        hasIterationsFeature,
        isGroup,
      },
      stubs: {
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback'],
        }),
        GlFormInput: stubComponent(GlFormInput, {
          props: ['state', 'disabled', 'value'],
          template: `<input />`,
        }),
      },
    });

    jest.advanceTimersByTime(SEARCH_DEBOUNCE);
    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findFormGroup = () => wrapper.findByTestId('work-items-create-form-group');
  const findWorkItemTokenInput = () => wrapper.findComponent(WorkItemTokenInput);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findConfidentialCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findAddChildButton = () => wrapper.findByTestId('add-child-button');
  const findValidationElement = () => wrapper.findByTestId('work-items-invalid');
  const findErrorMessageElement = () => wrapper.findByTestId('work-items-error');
  const findProjectSelector = () => wrapper.findComponent(WorkItemProjectsListbox);

  beforeEach(() => {
    gon.current_username = 'root';
  });

  it.each`
    workspace    | isGroup  | queryResolver
    ${'project'} | ${false} | ${namespaceWorkItemTypesResolver}
    ${'group'}   | ${true}  | ${namespaceWorkItemTypesResolver}
  `(
    'fetches $workspace work item types when isGroup is $isGroup',
    async ({ isGroup, queryResolver }) => {
      await createComponent({ isGroup });

      expect(queryResolver).toHaveBeenCalled();
    },
  );

  describe('creating a new work item', () => {
    describe('for project level work items', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('renders create form', () => {
        expect(findForm().exists()).toBe(true);
        expect(findInput().exists()).toBe(true);
        expect(findAddChildButton().text()).toBe('Create task');
        expect(findWorkItemTokenInput().exists()).toBe(false);
      });

      it('passes field validation details to form when create mutation fails', async () => {
        await createComponent({ createMutation: createMutationRejection });

        expect(findFormGroup().props('state')).toBe(true);
        expect(findFormGroup().props('invalidFeedback')).toBe(null);
        expect(findInput().props('state')).toBe(true);

        findInput().vm.$emit('input', 'Create task test');
        // Trigger form submission
        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();

        expect(findFormGroup().props('state')).toBe(false);
        expect(findFormGroup().props('invalidFeedback')).toBe(
          'Something went wrong when trying to create a child. Please try again.',
        );
        expect(findInput().props('state')).toBe(false);
      });

      it('creates child task in non confidential parent', async () => {
        findInput().vm.$emit('input', 'Create task test');

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();

        expect(createMutationResolver).toHaveBeenCalledWith({
          input: {
            title: 'Create task test',
            projectPath: 'group-a',
            workItemTypeId: workItemTypeIdForTask,
            hierarchyWidget: {
              parentId: 'gid://gitlab/WorkItem/1',
            },
            confidential: false,
          },
        });
        expect(wrapper.emitted('addChild')).toEqual([[]]);
      });

      it('creates child task in confidential parent', async () => {
        await createComponent({ parentConfidential: true });

        findInput().vm.$emit('input', 'Create confidential task');

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();
        expect(wrapper.vm.childWorkItemType).toEqual(workItemTypeIdForTask);
        expect(createMutationResolver).toHaveBeenCalledWith({
          input: {
            title: 'Create confidential task',
            projectPath: 'group-a',
            workItemTypeId: workItemTypeIdForTask,
            hierarchyWidget: {
              parentId: 'gid://gitlab/WorkItem/1',
            },
            confidential: true,
          },
        });
      });
    });

    describe('for group level work items', () => {
      beforeEach(async () => {
        await createComponent({
          isGroup: true,
          parentWorkItemType: WORK_ITEM_TYPE_VALUE_EPIC,
          childrenType: WORK_ITEM_TYPE_ENUM_ISSUE,
        });
      });

      it('renders create form with project selection', () => {
        expect(findForm().exists()).toBe(true);
        expect(findInput().exists()).toBe(true);
        expect(findAddChildButton().text()).toBe('Create issue');
        expect(findProjectSelector().exists()).toBe(true);
        expect(findWorkItemTokenInput().exists()).toBe(false);
      });

      it('creates child issue in non confidential parent', async () => {
        findInput().vm.$emit('input', 'Create issue test');

        findProjectSelector().vm.$emit('selectProject', projectData[0]);

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });

        await waitForPromises();

        expect(createMutationResolver).toHaveBeenCalledWith({
          input: {
            title: 'Create issue test',
            namespacePath: 'group-a/example-project-a',
            workItemTypeId: workItemTypeIdForIssue,
            hierarchyWidget: {
              parentId: 'gid://gitlab/WorkItem/1',
            },
            confidential: false,
          },
        });
        expect(wrapper.emitted('addChild')).toEqual([[]]);
      });

      it('creates child issue in confidential parent', async () => {
        await createComponent({
          parentConfidential: true,
          isGroup: true,
          parentWorkItemType: WORK_ITEM_TYPE_VALUE_EPIC,
          childrenType: WORK_ITEM_TYPE_ENUM_ISSUE,
        });

        findInput().vm.$emit('input', 'Create confidential issue');

        findProjectSelector().vm.$emit('selectProject', projectData[0]);

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });

        await waitForPromises();

        expect(createMutationResolver).toHaveBeenCalledWith({
          input: {
            title: 'Create confidential issue',
            namespacePath: 'group-a/example-project-a',
            workItemTypeId: workItemTypeIdForIssue,
            hierarchyWidget: {
              parentId: 'gid://gitlab/WorkItem/1',
            },
            confidential: true,
          },
        });
      });
    });

    describe('confidentiality checkbox', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('renders confidentiality checkbox', () => {
        const confidentialCheckbox = findConfidentialCheckbox();

        expect(confidentialCheckbox.exists()).toBe(true);
        expect(findTooltip().exists()).toBe(false);
        expect(confidentialCheckbox.text()).toBe(
          sprintf(I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL, {
            workItemType: WORK_ITEM_TYPE_ENUM_TASK.toLocaleLowerCase(),
          }),
        );
      });

      it('renders confidentiality tooltip with checkbox checked and disabled when parent is confidential', () => {
        createComponent({ parentConfidential: true });

        const confidentialCheckbox = findConfidentialCheckbox();

        expect(confidentialCheckbox.attributes('disabled')).toBeDefined();
        expect(confidentialCheckbox.attributes('checked')).toBe('true');
        expect(findTooltip().exists()).toBe(true);
        expect(findTooltip().text()).toBe(
          sprintf(I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP, {
            workItemType: WORK_ITEM_TYPE_ENUM_TASK.toLocaleLowerCase(),
            parentWorkItemType: WORK_ITEM_TYPE_VALUE_ISSUE.toLocaleLowerCase(),
          }),
        );
      });
    });

    it('doesnt include selected project when switching from project to group level child', async () => {
      await createComponent({
        parentConfidential: false,
        isGroup: true,
        parentWorkItemType: WORK_ITEM_TYPE_VALUE_EPIC,
        childrenType: WORK_ITEM_TYPE_ENUM_ISSUE,
      });

      findInput().vm.$emit('input', 'Pretending to add an issue');

      findProjectSelector().vm.$emit('selectProject', projectData[0]);

      await wrapper.setProps({
        childrenType: WORK_ITEM_TYPE_ENUM_EPIC,
      });

      findInput().vm.$emit('input', 'Actually adding an epic');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(createMutationResolver).toHaveBeenCalledWith({
        input: {
          title: 'Actually adding an epic',
          projectPath: 'group-a',
          workItemTypeId: workItemTypeIdForEpic,
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/1',
          },
          confidential: false,
        },
      });
    });

    it('requires project selection if group level work item creation is disabled', async () => {
      await createComponent({
        parentConfidential: false,
        isGroup: true,
        parentWorkItemType: WORK_ITEM_TYPE_VALUE_EPIC,
        childrenType: WORK_ITEM_TYPE_ENUM_ISSUE,
        createGroupLevelWorkItems: false,
      });

      findInput().vm.$emit('input', 'Example title');

      expect(findAddChildButton().props('disabled')).toBe(true);

      findProjectSelector().vm.$emit('selectProject', projectData[0]);

      await nextTick();

      expect(findAddChildButton().props('disabled')).toBe(false);
    });
  });

  describe('adding an existing work item', () => {
    const selectAvailableWorkItemTokens = (
      tokens = availableWorkItemsResponse.data.workspace.workItems.nodes,
    ) => {
      findWorkItemTokenInput().vm.$emit('input', tokens);
    };

    beforeEach(async () => {
      await createComponent({ formType: FORM_TYPES.add });
    });

    it('renders add form', () => {
      expect(findForm().exists()).toBe(true);
      expect(findWorkItemTokenInput().exists()).toBe(true);
      expect(findAddChildButton().text()).toBe('Add task');
      expect(findInput().exists()).toBe(false);
      expect(findConfidentialCheckbox().exists()).toBe(false);
    });

    it('renders work item token input with default props', () => {
      expect(findWorkItemTokenInput().props()).toMatchObject({
        value: [],
        fullPath: 'group-a',
        childrenType: WORK_ITEM_TYPE_ENUM_TASK,
        childrenIds: [],
        parentWorkItemId: 'gid://gitlab/WorkItem/1',
        areWorkItemsToAddValid: true,
      });
    });

    it('selects and adds children', async () => {
      await selectAvailableWorkItemTokens();

      expect(findAddChildButton().text()).toBe('Add tasks');
      expect(findWorkItemTokenInput().props('areWorkItemsToAddValid')).toBe(true);
      expect(findWorkItemTokenInput().props('value')).toBe(
        availableWorkItemsResponse.data.workspace.workItems.nodes,
      );
      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(updateMutationResolver).toHaveBeenCalled();
    });

    it('shows validation error when non-confidential child items are being added to confidential parent', async () => {
      await createComponent({ formType: FORM_TYPES.add, parentConfidential: true });

      await selectAvailableWorkItemTokens();

      expect(findWorkItemTokenInput().props('areWorkItemsToAddValid')).toBe(false);
      expect(findValidationElement().exists()).toBe(true);
      expect(findValidationElement().text().trim()).toBe(
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

    it('clears form error when token input is updated', async () => {
      await createComponent({ formType: FORM_TYPES.add, updateMutation: updateMutationRejection });
      await selectAvailableWorkItemTokens();

      // Trigger form submission
      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();

      // Assert if error was shown
      expect(findErrorMessageElement().exists()).toBe(true);

      // Trigger Token input update, causing error to clear
      await selectAvailableWorkItemTokens(
        availableWorkItemsResponse.data.workspace.workItems.nodes.slice(0, 2),
      );

      // Assert if error was cleared
      expect(findErrorMessageElement().exists()).toBe(false);
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
          projectPath: 'group-a',
          workItemTypeId: workItemTypeIdForTask,
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
          projectPath: 'group-a',
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
