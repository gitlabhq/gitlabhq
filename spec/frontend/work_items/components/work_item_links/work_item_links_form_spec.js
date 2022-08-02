import Vue from 'vue';
import { GlForm, GlFormInput, GlFormCombobox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import {
  availableWorkItemsResponse,
  createWorkItemMutationResponse,
  updateWorkItemMutationResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemLinksForm', () => {
  let wrapper;

  const updateMutationResolver = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const createMutationResolver = jest.fn().mockResolvedValue(createWorkItemMutationResponse);

  const createComponent = async ({ listResponse = availableWorkItemsResponse } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, jest.fn().mockResolvedValue(listResponse)],
        [updateWorkItemMutation, updateMutationResolver],
        [createWorkItemMutation, createMutationResolver],
      ]),
      propsData: { issuableGid: 'gid://gitlab/WorkItem/1' },
      provide: {
        projectPath: 'project/path',
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

  it('creates child task', async () => {
    findInput().vm.$emit('input', 'Create task test');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });
    await waitForPromises();
    expect(createMutationResolver).toHaveBeenCalled();
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
});
