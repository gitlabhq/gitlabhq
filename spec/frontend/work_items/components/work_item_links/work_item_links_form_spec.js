import Vue from 'vue';
import { GlForm, GlFormCombobox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { availableWorkItemsResponse, updateWorkItemMutationResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemLinksForm', () => {
  let wrapper;

  const updateMutationResolver = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const createComponent = async ({ listResponse = availableWorkItemsResponse } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinksForm, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, jest.fn().mockResolvedValue(listResponse)],
        [updateWorkItemMutation, updateMutationResolver],
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

  it('passes available work items as prop when typing in combobox', async () => {
    findCombobox().vm.$emit('input', 'Task');
    await waitForPromises();

    expect(findCombobox().exists()).toBe(true);
    expect(findCombobox().props('tokenList').length).toBe(2);
  });

  it('selects and add child', async () => {
    findCombobox().vm.$emit('input', availableWorkItemsResponse.data.workspace.workItems.edges[0]);

    findAddChildButton().vm.$emit('click');
    await waitForPromises();
    expect(updateMutationResolver).toHaveBeenCalled();
  });
});
