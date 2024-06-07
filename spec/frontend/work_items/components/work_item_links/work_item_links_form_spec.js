import Vue from 'vue';
import { GlForm, GlFormInput, GlFormCheckbox, GlTooltip } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import projectWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/project_work_item_types.query.graphql.json';
import groupWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/group_work_item_types.query.graphql.json';
import { sprintf, s__ } from '~/locale';
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
} from '~/work_items/constants';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import groupWorkItemTypesQuery from '~/work_items/graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import groupProjectsForLinksWidgetQuery from '~/work_items/graphql/group_projects_for_links_widget.query.graphql';
import relatedProjectsForLinksWidgetQuery from '~/work_items/graphql/related_projects_for_links_widget.query.graphql';
import {
  availableWorkItemsResponse,
  createWorkItemMutationResponse,
  updateWorkItemMutationResponse,
  mockIterationWidgetResponse,
  groupProjectsList,
  relatedProjectsList,
} from '../../mock_data';

Vue.use(VueApollo);

const projectData = groupProjectsList.data.group.projects.nodes;

const findWorkItemTypeId = (typeName) => {
  return projectWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.find(
    (node) => node.name === typeName,
  ).id;
};

const workItemTypeIdForTask = findWorkItemTypeId('Task');
const workItemTypeIdForIssue = findWorkItemTypeId('Issue');

describe('WorkItemLinksForm', () => {
  /**
   * @type {import('helpers/vue_test_utils_helper').ExtendedWrapper}
   */
  let wrapper;

  const updateMutationResolver = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const createMutationResolver = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const availableWorkItemsResolver = jest.fn().mockResolvedValue(availableWorkItemsResponse);
  const projectWorkItemTypesResolver = jest
    .fn()
    .mockResolvedValue(projectWorkItemTypesQueryResponse);
  const groupWorkItemTypesResolver = jest.fn().mockResolvedValue(groupWorkItemTypesQueryResponse);
  const groupProjectsFormLinksWidgetResolver = jest.fn().mockResolvedValue(groupProjectsList);
  const relatedProjectsForLinksWidgetResolver = jest.fn().mockResolvedValue(relatedProjectsList);

  const mockParentIteration = mockIterationWidgetResponse;

  const createComponent = async ({
    parentConfidential = false,
    hasIterationsFeature = false,
    parentIteration = null,
    formType = FORM_TYPES.create,
    parentWorkItemType = WORK_ITEM_TYPE_VALUE_ISSUE,
    childrenType = WORK_ITEM_TYPE_ENUM_TASK,
    isGroup = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, availableWorkItemsResolver],
        [projectWorkItemTypesQuery, projectWorkItemTypesResolver],
        [groupWorkItemTypesQuery, groupWorkItemTypesResolver],
        [groupProjectsForLinksWidgetQuery, groupProjectsFormLinksWidgetResolver],
        [relatedProjectsForLinksWidgetQuery, relatedProjectsForLinksWidgetResolver],
        [updateWorkItemMutation, updateMutationResolver],
        [createWorkItemMutation, createMutationResolver],
      ]),
      propsData: {
        fullPath: 'group-a',
        issuableGid: 'gid://gitlab/WorkItem/1',
        parentConfidential,
        parentIteration,
        parentWorkItemType,
        childrenType,
        formType,
      },
      provide: {
        hasIterationsFeature,
        isGroup,
      },
    });

    jest.advanceTimersByTime(SEARCH_DEBOUNCE);
    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findWorkItemTokenInput = () => wrapper.findComponent(WorkItemTokenInput);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findConfidentialCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findAddChildButton = () => wrapper.findByTestId('add-child-button');
  const findValidationElement = () => wrapper.findByTestId('work-items-invalid');
  const findProjectSelector = () => wrapper.findComponent(WorkItemProjectsListbox);

  beforeEach(() => {
    gon.current_username = 'root';
  });

  it.each`
    workspace    | isGroup  | queryResolver
    ${'project'} | ${false} | ${projectWorkItemTypesResolver}
    ${'group'}   | ${true}  | ${groupWorkItemTypesResolver}
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
  });

  describe('adding an existing work item', () => {
    const selectAvailableWorkItemTokens = () => {
      findWorkItemTokenInput().vm.$emit(
        'input',
        availableWorkItemsResponse.data.workspace.workItems.nodes,
      );
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
