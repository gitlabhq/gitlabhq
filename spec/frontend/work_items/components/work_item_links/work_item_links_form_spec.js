import Vue, { nextTick } from 'vue';
import { GlForm, GlFormGroup, GlFormInput, GlFormCheckbox, GlTooltip } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import WorkItemGroupsListbox from '~/work_items/components/work_item_links/work_item_groups_listbox.vue';
import WorkItemProjectsListbox from '~/work_items/components/work_item_links/work_item_projects_listbox.vue';
import {
  FORM_TYPES,
  MAX_WORK_ITEMS,
  SEARCH_DEBOUNCE,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_TASK,
} from '~/work_items/constants';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateWorkItemHierarchyMutation from '~/work_items/graphql/update_work_item_hierarchy.mutation.graphql';
import namespaceProjectsForLinksWidgetQuery from '~/work_items/graphql/namespace_projects_for_links_widget.query.graphql';
import {
  availableWorkItemsResponse,
  createWorkItemMutationResponse,
  generateWorkItemsListWithId,
  namespaceProjectsList,
  namespaceWorkItemTypesQueryResponse,
  updateWorkItemMutationResponse,
} from 'ee_else_ce_jest/work_items/mock_data';

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

  const createComponent = async ({
    parentConfidential = false,
    hasIterationsFeature = false,
    parentIteration = null,
    parentMilestone = null,
    formType = FORM_TYPES.create,
    parentWorkItemType = WORK_ITEM_TYPE_NAME_ISSUE,
    childrenType = WORK_ITEM_TYPE_NAME_TASK,
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
        isGroup,
        issuableGid: 'gid://gitlab/WorkItem/1',
        parentConfidential,
        parentIteration,
        parentMilestone,
        parentWorkItemType,
        childrenType,
        formType,
        glFeatures: {
          createGroupLevelWorkItems,
        },
      },
      provide: {
        hasIterationsFeature,
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
  const findWorkItemLimitValidationMessage = () => wrapper.findByTestId('work-items-limit-error');
  const findErrorMessageElement = () => wrapper.findByTestId('work-items-error');
  const findGroupsSelector = () => wrapper.findComponent(WorkItemGroupsListbox);
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
    const submitForm = ({ title, fullPath }) => {
      findInput().vm.$emit('input', title);

      if (fullPath) {
        findProjectSelector().vm.$emit('selectProject', fullPath);
      }

      // Trigger form submission
      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
    };

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

        submitForm({ title: 'Create task test' });

        expect(wrapper.emitted('update-in-progress')).toEqual([[true]]);

        await waitForPromises();

        expect(findFormGroup().props('state')).toBe(false);
        expect(findFormGroup().props('invalidFeedback')).toBe(
          'Something went wrong when trying to create a child. Please try again.',
        );
        expect(findInput().props('state')).toBe(false);
        expect(wrapper.emitted('update-in-progress')[1]).toEqual([false]);
      });

      it('creates child task in non confidential parent', async () => {
        submitForm({ title: 'Create task test' });

        expect(wrapper.emitted('update-in-progress')).toEqual([[true]]);

        await waitForPromises();

        expect(createMutationResolver).toHaveBeenCalledWith({
          input: {
            title: 'Create task test',
            namespacePath: 'group-a',
            workItemTypeId: workItemTypeIdForTask,
            hierarchyWidget: {
              parentId: 'gid://gitlab/WorkItem/1',
            },
            confidential: false,
          },
        });
        expect(wrapper.emitted('addChild')).toEqual([[]]);
        expect(wrapper.emitted('update-in-progress')[1]).toEqual([false]);
      });

      it('creates child task in confidential parent', async () => {
        await createComponent({ parentConfidential: true });

        submitForm({ title: 'Create confidential task' });

        expect(wrapper.emitted('update-in-progress')).toEqual([[true]]);

        await waitForPromises();

        expect(createMutationResolver).toHaveBeenCalledWith({
          input: {
            title: 'Create confidential task',
            namespacePath: 'group-a',
            workItemTypeId: workItemTypeIdForTask,
            hierarchyWidget: {
              parentId: 'gid://gitlab/WorkItem/1',
            },
            confidential: true,
          },
        });
        expect(wrapper.emitted('update-in-progress')[1]).toEqual([false]);
      });
    });

    describe('for group level work items', () => {
      beforeEach(async () => {
        await createComponent({
          isGroup: true,
          parentWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          childrenType: WORK_ITEM_TYPE_NAME_ISSUE,
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
        submitForm({ title: 'Create issue test', fullPath: projectData[0].fullPath });

        expect(wrapper.emitted('update-in-progress')).toEqual([[true]]);

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
        expect(wrapper.emitted('update-in-progress')[1]).toEqual([false]);
      });

      it('creates child issue in confidential parent', async () => {
        await createComponent({
          parentConfidential: true,
          isGroup: true,
          parentWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          childrenType: WORK_ITEM_TYPE_NAME_ISSUE,
        });

        submitForm({ title: 'Create confidential issue', fullPath: projectData[0].fullPath });

        expect(wrapper.emitted('update-in-progress')).toEqual([[true]]);

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
        expect(wrapper.emitted('update-in-progress')[1]).toEqual([false]);
      });
    });

    describe('for epic work item', () => {
      beforeEach(async () => {
        await createComponent({
          isGroup: true,
          parentWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
          childrenType: WORK_ITEM_TYPE_NAME_EPIC,
        });
      });

      it('renders create form with group selection', () => {
        expect(findInput().exists()).toBe(true);
        expect(findGroupsSelector().props()).toMatchObject({
          fullPath: 'group-a',
          selectedGroupFullPath: 'group-a',
        });
        expect(findAddChildButton().text()).toBe('Create epic');
      });
    });

    describe('confidentiality checkbox', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('renders confidentiality checkbox', () => {
        const confidentialCheckbox = findConfidentialCheckbox();

        expect(findTooltip().exists()).toBe(false);
        expect(confidentialCheckbox.text()).toBe(
          'Turn on confidentiality: Limit visibility to project members with at least the Planner role.',
        );
      });

      it('renders confidentiality tooltip with checkbox checked and disabled when parent is confidential', () => {
        createComponent({ parentConfidential: true });

        const confidentialCheckbox = findConfidentialCheckbox();

        expect(confidentialCheckbox.attributes('disabled')).toBeDefined();
        expect(confidentialCheckbox.attributes('checked')).toBe('true');
        expect(findTooltip().text()).toBe(
          'A non-confidential task cannot be assigned to a confidential parent issue.',
        );
      });
    });

    it('doesnt include selected project when switching from project to group level child', async () => {
      await createComponent({
        parentConfidential: false,
        isGroup: true,
        parentWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
        childrenType: WORK_ITEM_TYPE_NAME_ISSUE,
      });

      findInput().vm.$emit('input', 'Pretending to add an issue');

      findProjectSelector().vm.$emit('selectProject', projectData[0]);

      await wrapper.setProps({ childrenType: WORK_ITEM_TYPE_NAME_EPIC });

      findInput().vm.$emit('input', 'Actually adding an epic');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(createMutationResolver).toHaveBeenCalledWith({
        input: {
          title: 'Actually adding an epic',
          namespacePath: 'group-a',
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
        parentWorkItemType: WORK_ITEM_TYPE_NAME_EPIC,
        childrenType: WORK_ITEM_TYPE_NAME_ISSUE,
        createGroupLevelWorkItems: false,
      });

      findInput().vm.$emit('input', 'Example title');

      expect(findAddChildButton().props('disabled')).toBe(true);

      findProjectSelector().vm.$emit('selectProject', projectData[0].fullPath);

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
        childrenType: WORK_ITEM_TYPE_NAME_TASK,
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
      expect(findValidationElement().text()).toBe(
        'Task 1, Task 2, Task 3 cannot be added: Cannot assign a non-confidential task to a confidential parent issue. Make the selected task confidential and try again.',
      );
    });

    it('disables button ans shows validation error when more than 10 work items are selected', async () => {
      await selectAvailableWorkItemTokens(generateWorkItemsListWithId(MAX_WORK_ITEMS + 1));

      expect(findWorkItemTokenInput().props('areWorkItemsToAddValid')).toBe(false);
      expect(findAddChildButton().attributes().disabled).toBe('true');
      expect(findWorkItemLimitValidationMessage().exists()).toBe(true);
      expect(findWorkItemLimitValidationMessage().text()).toContain(
        'Only 10 items can be added at a time.',
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
});
