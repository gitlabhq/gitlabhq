import Vue from 'vue';
import { GlForm, GlFormInput, GlTokenSelector } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import { FORM_TYPES } from '~/work_items/constants';
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
    workItemsMvcEnabled = false,
    parentIteration = null,
    formType = FORM_TYPES.create,
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
        formType,
      },
      provide: {
        glFeatures: {
          workItemsMvc: workItemsMvcEnabled,
        },
        projectPath: 'project/path',
        hasIterationsFeature,
      },
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findAddChildButton = () => wrapper.findByTestId('add-child-button');

  afterEach(() => {
    wrapper.destroy();
  });

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
  });

  describe('adding an existing work item', () => {
    beforeEach(async () => {
      await createComponent({ formType: FORM_TYPES.add });
    });

    it('renders add form', () => {
      expect(findForm().exists()).toBe(true);
      expect(findTokenSelector().exists()).toBe(true);
      expect(findAddChildButton().text()).toBe('Add task');
      expect(findInput().exists()).toBe(false);
    });

    it('searches for available work items as prop when typing in input', async () => {
      findTokenSelector().vm.$emit('focus');
      findTokenSelector().vm.$emit('text-input', 'Task');
      await waitForPromises();

      expect(availableWorkItemsResolver).toHaveBeenCalled();
    });

    it('selects and adds children', async () => {
      findTokenSelector().vm.$emit(
        'input',
        availableWorkItemsResponse.data.workspace.workItems.nodes,
      );
      findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));

      await waitForPromises();

      expect(findAddChildButton().text()).toBe('Add tasks');
      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(updateMutationResolver).toHaveBeenCalled();
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
