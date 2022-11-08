import Vue from 'vue';
import { GlForm, GlFormInput, GlFormCombobox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
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

  const mockParentIteration = mockIterationWidgetResponse;

  const createComponent = async ({
    listResponse = availableWorkItemsResponse,
    typesResponse = projectWorkItemTypesQueryResponse,
    parentConfidential = false,
    hasIterationsFeature = false,
    workItemsMvc2Enabled = false,
    parentIteration = null,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, jest.fn().mockResolvedValue(listResponse)],
        [projectWorkItemTypesQuery, jest.fn().mockResolvedValue(typesResponse)],
        [updateWorkItemMutation, updateMutationResolver],
        [createWorkItemMutation, createMutationResolver],
      ]),
      propsData: { issuableGid: 'gid://gitlab/WorkItem/1', parentConfidential, parentIteration },
      provide: {
        glFeatures: {
          workItemsMvc2: workItemsMvc2Enabled,
        },
        projectPath: 'project/path',
        hasIterationsFeature,
      },
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findCombobox = () => wrapper.findComponent(GlFormCombobox);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findAddChildButton = () => wrapper.findByTestId('add-child-button');

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders form', () => {
    expect(findForm().exists()).toBe(true);
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

  // Follow up issue to turn this functionality back on https://gitlab.com/gitlab-org/gitlab/-/issues/368757
  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('selects and add child', async () => {
    findCombobox().vm.$emit('input', availableWorkItemsResponse.data.workspace.workItems.edges[0]);

    findAddChildButton().vm.$emit('click');
    await waitForPromises();
    expect(updateMutationResolver).toHaveBeenCalled();
  });

  // eslint-disable-next-line jest/no-disabled-tests
  describe.skip('when typing in combobox', () => {
    beforeEach(async () => {
      findCombobox().vm.$emit('input', 'Task');
      await waitForPromises();
      await jest.runOnlyPendingTimers();
    });

    it('passes available work items as prop', () => {
      expect(findCombobox().exists()).toBe(true);
      expect(findCombobox().props('tokenList').length).toBe(2);
    });

    it('passes action to create task', () => {
      expect(findCombobox().props('actionList').length).toBe(1);
    });
  });

  describe('associate iteration with task', () => {
    it('does not update iteration when mvc2 feature flag is not enabled', async () => {
      await createComponent({
        hasIterationsFeature: true,
        parentIteration: mockParentIteration,
      });

      findInput().vm.$emit('input', 'Create task test');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(updateMutationResolver).not.toHaveBeenCalled();
    });
    it('updates when parent has an iteration associated', async () => {
      await createComponent({
        workItemsMvc2Enabled: true,
        hasIterationsFeature: true,
        parentIteration: mockParentIteration,
      });
      findInput().vm.$emit('input', 'Create task test');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(updateMutationResolver).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          iterationWidget: {
            iterationId: mockParentIteration.id,
          },
        },
      });
    });
    it('does not update when parent has no iteration associated', async () => {
      await createComponent({
        workItemsMvc2Enabled: true,
        hasIterationsFeature: true,
      });
      findInput().vm.$emit('input', 'Create task test');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });
      await waitForPromises();
      expect(updateMutationResolver).not.toHaveBeenCalled();
    });
  });
});
