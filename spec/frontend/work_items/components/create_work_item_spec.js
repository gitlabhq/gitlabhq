import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import projectWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/project_work_item_types.query.graphql.json';
import groupWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/group_work_item_types.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';
import groupWorkItemTypesQuery from '~/work_items/graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import { createWorkItemMutationResponse, createWorkItemQueryResponse } from '../mock_data';

const projectSingleWorkItemTypeQueryResponse = {
  data: {
    workspace: {
      ...projectWorkItemTypesQueryResponse.data.workspace,
      workItemTypes: {
        nodes: [projectWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes[0]],
      },
    },
  },
};

Vue.use(VueApollo);

describe('Create work item component', () => {
  let wrapper;
  let mockApollo;

  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');
  const projectWorkItemQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(createWorkItemQueryResponse);
  const groupWorkItemQuerySuccessHandler = jest.fn().mockResolvedValue(createWorkItemQueryResponse);

  const findFormTitle = () => wrapper.find('h1');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(WorkItemTitle);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findConfidentialCheckbox = () => wrapper.find('[data-testid="confidential-checkbox"]');

  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');

  const createComponent = ({
    data = {},
    props = {},
    isGroup = false,
    mutationHandler = createWorkItemSuccessHandler,
    singleWorkItemType = false,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [createWorkItemMutation, mutationHandler],
        [groupWorkItemByIidQuery, groupWorkItemQuerySuccessHandler],
        [workItemByIidQuery, projectWorkItemQuerySuccessHandler],
      ],
      resolvers,
      { typePolicies: { Project: { merge: true } } },
    );

    const projectWorkItemTypeResponse = singleWorkItemType
      ? projectSingleWorkItemTypeQueryResponse
      : projectWorkItemTypesQueryResponse;
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: isGroup ? groupWorkItemTypesQuery : projectWorkItemTypesQuery,
      variables: { fullPath: 'full-path', name: 'EPIC' },
      data: isGroup
        ? {
            ...groupWorkItemTypesQueryResponse.data,
          }
        : {
            ...projectWorkItemTypeResponse.data,
          },
    });

    wrapper = shallowMount(CreateWorkItem, {
      apolloProvider: mockApollo,
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        workItemTypeName: WORK_ITEM_TYPE_ENUM_EPIC,
        ...props,
      },
      provide: {
        fullPath: 'full-path',
        isGroup,
        hasIssuableHealthStatusFeature: false,
      },
    });
  };

  it('does not render error by default', async () => {
    createComponent();

    await waitForPromises();

    expect(findTitleInput().props('isValid')).toBe(true);
    expect(findAlert().exists()).toBe(false);
  });

  it('emits event on Cancel button click', async () => {
    createComponent();

    await waitForPromises();

    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toEqual([[]]);
  });

  it('emits workItemCreated on successful mutation', async () => {
    createComponent();

    await waitForPromises();

    findTitleInput().vm.$emit('updateDraft', 'Test title');
    await waitForPromises();

    wrapper.find('form').trigger('submit');
    await waitForPromises();

    await waitForPromises();
    expect(wrapper.emitted('workItemCreated')).toEqual([
      [createWorkItemMutationResponse.data.workItemCreate.workItem],
    ]);
  });

  it('emits workItemCreated for confidential work item', async () => {
    createComponent();

    await waitForPromises();

    findTitleInput().vm.$emit('updateDraft', 'Test title');
    findConfidentialCheckbox().vm.$emit('change', true);
    await waitForPromises();

    wrapper.find('form').trigger('submit');
    await waitForPromises();

    await waitForPromises();

    expect(createWorkItemSuccessHandler).toHaveBeenCalledWith({
      input: expect.objectContaining({
        title: 'Test title',
        confidential: true,
      }),
    });
  });

  it('does not commit when title is empty', async () => {
    createComponent();

    await waitForPromises();

    findTitleInput().vm.$emit('updateDraft', ' ');

    wrapper.find('form').trigger('submit');
    await waitForPromises();

    expect(findTitleInput().props('isValid')).toBe(false);
    expect(wrapper.emitted('workItemCreated')).toEqual(undefined);
  });

  it('displays a list of project work item types', async () => {
    createComponent();
    await waitForPromises();

    // +1 for the "None" option
    const expectedOptions =
      projectWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.length + 1;

    expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
  });

  it('fetches group work item types when isGroup is true', async () => {
    createComponent({
      isGroup: true,
    });

    await waitForPromises();

    const expectedOptions =
      groupWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes.length + 1;

    expect(findSelect().attributes('options').split(',')).toHaveLength(expectedOptions);
  });

  it('hides the select field if there is only a single type', async () => {
    createComponent({
      singleWorkItemType: true,
    });
    await waitForPromises();

    expect(findSelect().exists()).toBe(false);
  });

  it('selects a work item type on click', async () => {
    createComponent();
    await waitForPromises();

    const mockId = 'work-item-1';
    findSelect().vm.$emit('input', mockId);
    await nextTick();

    expect(findSelect().attributes('value')).toBe(mockId);
  });

  it('hides title if set', async () => {
    createComponent({
      props: { hideFormTitle: true },
    });

    await waitForPromises();

    expect(findFormTitle().exists()).toBe(false);
  });

  it('updates work item title on update mutation', async () => {
    createComponent();

    await waitForPromises();

    findTitleInput().vm.$emit('updateDraft', 'Test title');
    await waitForPromises();
    await nextTick();

    expect(findTitleInput().props('title')).toBe('Test title');
  });

  describe('when title input field has a text', () => {
    beforeEach(async () => {
      const mockTitle = 'Test title';
      createComponent();
      await waitForPromises();
      findTitleInput().vm.$emit('updateDraft', mockTitle);
    });

    it('renders Create button when work item type is selected', async () => {
      findSelect().vm.$emit('input', 'work-item-1');
      await nextTick();
      expect(findCreateButton().props('disabled')).toBe(false);
    });
  });

  it('shows an alert on mutation error', async () => {
    createComponent({ mutationHandler: errorHandler });
    await waitForPromises();
    findTitleInput().vm.$emit('updateDraft', 'some title');
    findSelect().vm.$emit('input', 'work-item-1');
    await waitForPromises();

    wrapper.find('form').trigger('submit');
    await waitForPromises();

    expect(findAlert().text()).toBe('Something went wrong when creating item. Please try again.');
  });
});
