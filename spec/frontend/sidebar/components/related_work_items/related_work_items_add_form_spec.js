import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlIcon, GlCollapsibleListbox, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import RelatedWorkItemsAddForm from '~/sidebar/components/related_work_items/related_work_items_add_form.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import recentlyViewedWorkItemsQuery from '~/sidebar/queries/recently_viewed_work_items.query.graphql';
import mergeRequestRelatedWorkItemsQuery from '~/sidebar/queries/merge_request_related_work_items.query.graphql';
import createMergeRequestWorkItemRelationMutation from '~/sidebar/queries/create_merge_request_work_item_relation.mutation.graphql';
import { MR_WORK_ITEM_RELATIONSHIP_OPTIONS } from '~/sidebar/constants';

jest.mock('~/alert');

Vue.use(VueApollo);

const MOCK_MERGE_REQUEST_ID = 'gid://gitlab/MergeRequest/1';
const MOCK_MERGE_REQUEST_IID = '1';

const recentlyViewedResponse = (items) => ({
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      recentlyViewedIssues: items,
      __typename: 'CurrentUser',
    },
  },
});

const issueItem = {
  id: 'gid://gitlab/Issue/2',
  title: 'A recently viewed issue',
  webUrl: '/group/project/-/issues/2',
  reference: 'group/project#2',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/2',
    name: 'Issue',
    iconName: 'issue-type-issue',
    __typename: 'WorkItemType',
  },
  __typename: 'Issue',
};

const issueItemWithoutIcon = {
  id: 'gid://gitlab/Issue/3',
  title: 'Another recently viewed issue',
  webUrl: '/group/project/-/issues/3',
  reference: 'group/project#3',
  workItemType: {
    id: 'gid://gitlab/WorkItems::Type/3',
    name: 'Issue',
    iconName: null,
    __typename: 'WorkItemType',
  },
  __typename: 'Issue',
};

const workItemToLink = {
  id: 'gid://gitlab/WorkItem/101',
  iid: '11',
  title: 'New related item',
  webPath: '/group/project/-/work_items/11',
  webUrl: '/group/project/-/work_items/11',
  namespace: {
    id: 'gid://gitlab/Project/7',
    fullPath: 'group/project',
    __typename: 'Namespace',
  },
  __typename: 'WorkItem',
};

const createdRelation = {
  id: 'gid://gitlab/MergeRequestsClosingIssues/1',
  linkType: 'CLOSES',
  fromMrDescription: false,
  workItem: workItemToLink,
  __typename: 'MergeRequestWorkItemRelation',
};

const createMutationResponse = (workItemRelations = [createdRelation], errors = []) => ({
  data: {
    mergeRequestCreateWorkItemRelations: {
      errors,
      workItemRelations,
      __typename: 'MergeRequestCreateWorkItemRelationsPayload',
    },
  },
});

describe('RelatedWorkItemsAddForm', () => {
  let wrapper;
  let mockApollo;

  const findRecentItems = () => wrapper.findAllByTestId('recently-viewed-item');
  const findRelationshipListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findTokenInput = () => wrapper.findComponent(WorkItemTokenInput);
  const findCreateModal = () => wrapper.findComponent(CreateWorkItemModal);
  const findCreateButton = () => wrapper.findComponentByTestId('add-work-item-create');
  const findConfirmButton = () => wrapper.findComponentByTestId('add-work-item-confirm');
  const findModal = () => wrapper.findComponent(GlModal);
  const findError = () => wrapper.findComponent(GlAlert);

  const selectAndAdd = async (workItems = [workItemToLink]) => {
    findTokenInput().vm.$emit('input', workItems);
    await nextTick();
    findConfirmButton().vm.$emit('click');
    await waitForPromises();
  };

  const readRelationsFromCache = (explicitMrWorkItemRelations = true) =>
    mockApollo.clients.defaultClient.cache.readQuery({
      query: mergeRequestRelatedWorkItemsQuery,
      variables: { id: MOCK_MERGE_REQUEST_ID, explicitMrWorkItemRelations },
    })?.mergeRequest;

  const createComponent = ({
    queryHandler = jest
      .fn()
      .mockResolvedValue(recentlyViewedResponse([issueItem, issueItemWithoutIcon])),
    mutationHandler = jest.fn().mockResolvedValue(createMutationResponse()),
    propsData = {},
    provide = {},
  } = {}) => {
    mockApollo = createMockApollo([
      [recentlyViewedWorkItemsQuery, queryHandler],
      [createMergeRequestWorkItemRelationMutation, mutationHandler],
    ]);

    wrapper = shallowMountExtended(RelatedWorkItemsAddForm, {
      apolloProvider: mockApollo,
      provide: {
        glFeatures: { explicitMrWorkItemRelations: true },
        ...provide,
      },
      propsData: {
        fullPath: 'group/project',
        mergeRequestId: MOCK_MERGE_REQUEST_ID,
        mergeRequestIid: MOCK_MERGE_REQUEST_IID,
        visible: true,
        ...propsData,
      },
    });
  };

  it('fetches the current user recently viewed issues', async () => {
    const queryHandler = jest.fn().mockResolvedValue(recentlyViewedResponse([issueItem]));
    createComponent({ queryHandler });
    await waitForPromises();

    expect(queryHandler).toHaveBeenCalledTimes(1);
  });

  it('renders a row for each fetched recently viewed issue', async () => {
    createComponent();
    await waitForPromises();

    expect(findRecentItems()).toHaveLength(2);
    expect(findRecentItems().at(0).text()).toContain('A recently viewed issue');
    expect(findRecentItems().at(1).text()).toContain('Another recently viewed issue');
  });

  it('renders the reference for each recently viewed issue', async () => {
    createComponent();
    await waitForPromises();

    expect(
      findRecentItems().at(0).find('[data-testid="recently-viewed-item-reference"]').text(),
    ).toBe('group/project#2');
    expect(
      findRecentItems().at(1).find('[data-testid="recently-viewed-item-reference"]').text(),
    ).toBe('group/project#3');
  });

  it('maps an issue to its type icon and falls back to the default issue icon', async () => {
    createComponent();
    await waitForPromises();

    const icons = wrapper.findAllComponents(GlIcon);
    expect(icons.at(0).props('name')).toBe('issue-type-issue');
    expect(icons.at(1).props('name')).toBe('work-item-issue');
  });

  it('renders no recently viewed rows when the query returns an empty list', async () => {
    createComponent({ queryHandler: jest.fn().mockResolvedValue(recentlyViewedResponse([])) });
    await waitForPromises();

    expect(findRecentItems()).toHaveLength(0);
  });

  it('shows an alert when the recently viewed items query fails', async () => {
    const error = new Error('Query failed');
    createComponent({ queryHandler: jest.fn().mockRejectedValue(error) });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while fetching recently viewed items.',
      error,
      captureError: true,
    });
  });

  describe('relationship selector', () => {
    it('offers the Closes and Relates to relationship types by default', () => {
      createComponent();

      expect(findRelationshipListbox().props('items')).toEqual(MR_WORK_ITEM_RELATIONSHIP_OPTIONS);
    });

    it('selects Closes as the default relationship type', () => {
      createComponent();

      expect(findRelationshipListbox().props('selected')).toBe('CLOSES');
      expect(findRelationshipListbox().props('toggleText')).toBe('Closes');
    });

    it('updates the toggle text when a different relationship type is selected', async () => {
      createComponent();

      await findRelationshipListbox().vm.$emit('select', 'RELATED');

      expect(findRelationshipListbox().props('toggleText')).toBe('Relates to');
    });
  });

  describe('work item search', () => {
    it('renders a work item token input scoped to the full path', () => {
      createComponent();

      expect(findTokenInput().props('fullPath')).toBe('group/project');
    });
  });

  describe('hiding the modal', () => {
    it('emits hide when the modal is hidden', () => {
      createComponent();

      findModal().vm.$emit('hide');

      expect(wrapper.emitted('hide')).toHaveLength(1);
    });
  });

  describe('creating a new work item', () => {
    it('opens the create work item modal when the create button is clicked', async () => {
      createComponent();

      expect(findCreateModal().props('visible')).toBe(false);

      await findCreateButton().vm.$emit('click');

      expect(findCreateModal().props('visible')).toBe(true);
    });

    it('passes the related item creation context to the create modal', () => {
      createComponent();

      expect(findCreateModal().props('creationContext')).toBe('related-item');
    });

    it('lets the user pick any work item type and any project', () => {
      createComponent();

      expect(findCreateModal().props()).toMatchObject({
        alwaysShowWorkItemTypeSelect: true,
        allowAnyNamespace: true,
        allowProjectsOnly: true,
      });
    });

    it('passes the merge request id and selected relationship type to the create modal', async () => {
      createComponent({ propsData: { mergeRequestId: 'gid://gitlab/MergeRequest/7' } });
      await findRelationshipListbox().vm.$emit('select', 'RELATED');

      expect(findCreateModal().props('mergeRequestId')).toBe('gid://gitlab/MergeRequest/7');
      expect(findCreateModal().props('mergeRequestLinkType')).toBe('RELATED');
    });

    it('emits "created" with the new item and link type, without linking via the relation mutation', async () => {
      const createdWorkItem = {
        id: 'gid://gitlab/WorkItem/99',
        iid: '99',
        title: 'Brand new item',
        __typename: 'WorkItem',
      };
      const mutationHandler = jest.fn().mockResolvedValue(createMutationResponse());
      createComponent({ mutationHandler });
      await findRelationshipListbox().vm.$emit('select', 'RELATED');

      findCreateModal().vm.$emit('work-item-created', createdWorkItem);

      expect(wrapper.emitted('created')).toEqual([
        [{ workItem: createdWorkItem, linkType: 'RELATED' }],
      ]);
      expect(mutationHandler).not.toHaveBeenCalled();
    });

    it('hides the create modal after a work item is created', async () => {
      createComponent();
      await findCreateButton().vm.$emit('click');
      expect(findCreateModal().props('visible')).toBe(true);

      findCreateModal().vm.$emit('work-item-created', {
        id: 'gid://gitlab/WorkItem/99',
        __typename: 'WorkItem',
      });
      await waitForPromises();

      expect(findCreateModal().props('visible')).toBe(false);
    });

    it('can reopen the create modal after it is closed via cancel', async () => {
      createComponent();

      await findCreateButton().vm.$emit('click');
      expect(findCreateModal().props('visible')).toBe(true);

      // The create modal emits `hide-modal` when the user cancels/discards.
      findCreateModal().vm.$emit('hide-modal');
      await waitForPromises();
      expect(findCreateModal().props('visible')).toBe(false);

      await findCreateButton().vm.$emit('click');
      expect(findCreateModal().props('visible')).toBe(true);
    });
  });

  describe('linking work items', () => {
    const seedCache = ({ explicitMrWorkItemRelations = true } = {}) => {
      mockApollo.clients.defaultClient.cache.writeQuery({
        query: mergeRequestRelatedWorkItemsQuery,
        variables: { id: MOCK_MERGE_REQUEST_ID, explicitMrWorkItemRelations },
        data: {
          mergeRequest: {
            id: MOCK_MERGE_REQUEST_ID,
            iid: MOCK_MERGE_REQUEST_IID,
            title: 'Fix the bug',
            reference: 'group/project!1',
            ...(explicitMrWorkItemRelations
              ? {
                  userPermissions: {
                    adminMergeRequest: true,
                    __typename: 'MergeRequestPermissions',
                  },
                  workItemRelations: {
                    nodes: [],
                    __typename: 'MergeRequestWorkItemRelationConnection',
                  },
                }
              : {}),
            linkedWorkItems: [],
            __typename: 'MergeRequest',
          },
        },
      });
    };

    it('calls the create mutation with the selected items and relationship type', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(createMutationResponse());
      createComponent({ mutationHandler });

      await findRelationshipListbox().vm.$emit('select', 'RELATED');
      await selectAndAdd();

      expect(mutationHandler).toHaveBeenCalledWith({
        projectPath: 'group/project',
        iid: MOCK_MERGE_REQUEST_IID,
        workItemIds: [workItemToLink.id],
        linkType: 'RELATED',
      });
    });

    it('links a recently viewed item when its row is clicked', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(createMutationResponse());
      createComponent({ mutationHandler });
      await waitForPromises();

      findRecentItems().at(0).trigger('click');
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledWith({
        projectPath: 'group/project',
        iid: MOCK_MERGE_REQUEST_IID,
        workItemIds: [issueItem.id],
        linkType: 'CLOSES',
      });
    });

    it('shows the loading state on the add button while the mutation is in flight', async () => {
      createComponent();

      findTokenInput().vm.$emit('input', [workItemToLink]);
      await nextTick();
      findConfirmButton().vm.$emit('click');
      await nextTick();

      expect(findConfirmButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(findConfirmButton().props('loading')).toBe(false);
    });

    it('does not start a second mutation while one is in flight', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(createMutationResponse());
      createComponent({ mutationHandler });
      await waitForPromises();

      findRecentItems().at(0).trigger('click');
      findRecentItems().at(1).trigger('click');
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledTimes(1);
    });

    describe('when the mutation succeeds', () => {
      it('emits "linked" with the number of linked items', async () => {
        createComponent();

        await selectAndAdd([
          workItemToLink,
          { ...workItemToLink, id: 'gid://gitlab/WorkItem/102' },
        ]);

        expect(wrapper.emitted('linked')).toEqual([[{ count: 2 }]]);
      });

      it('does not show an error', async () => {
        createComponent();

        await selectAndAdd();

        expect(findError().exists()).toBe(false);
      });

      it('adds the new relation to the merge request relations in the cache', async () => {
        createComponent();
        seedCache();

        await selectAndAdd();

        expect(readRelationsFromCache().workItemRelations.nodes).toEqual([createdRelation]);
      });

      it('adds the new relation to the linked work items when the feature flag is disabled', async () => {
        createComponent({ provide: { glFeatures: { explicitMrWorkItemRelations: false } } });
        seedCache({ explicitMrWorkItemRelations: false });

        await selectAndAdd();

        expect(readRelationsFromCache(false).linkedWorkItems).toEqual([
          {
            linkType: createdRelation.linkType,
            workItem: workItemToLink,
            __typename: 'LinkedWorkItem',
          },
        ]);
      });
    });

    describe('when the mutation returns errors', () => {
      const mutationHandler = () =>
        jest.fn().mockResolvedValue(createMutationResponse([], ['Work item could not be linked.']));

      it('shows the returned error in the modal', async () => {
        createComponent({ mutationHandler: mutationHandler() });

        await selectAndAdd();

        expect(findError().text()).toBe('Work item could not be linked.');
        expect(findError().props('variant')).toBe('danger');
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('does not emit "linked"', async () => {
        createComponent({ mutationHandler: mutationHandler() });

        await selectAndAdd();

        expect(wrapper.emitted('linked')).toBeUndefined();
      });

      it('hides the error when the user dismisses it', async () => {
        createComponent({ mutationHandler: mutationHandler() });
        await selectAndAdd();

        findError().vm.$emit('dismiss');
        await nextTick();

        expect(findError().exists()).toBe(false);
      });

      it('does not show the error again when the modal is reopened', async () => {
        let rejectMutation;
        createComponent({
          mutationHandler: jest.fn().mockImplementation(
            () =>
              new Promise((resolve, reject) => {
                rejectMutation = reject;
              }),
          ),
        });

        findTokenInput().vm.$emit('input', [workItemToLink]);
        await nextTick();
        findConfirmButton().vm.$emit('click');
        await nextTick();

        // The user gives up and closes the modal while the request is in flight.
        await wrapper.setProps({ visible: false });
        rejectMutation(new Error('Network error'));
        await waitForPromises();

        await wrapper.setProps({ visible: true });

        expect(findError().exists()).toBe(false);
      });

      it('hides the error when the modal is closed', async () => {
        createComponent({ mutationHandler: mutationHandler() });
        await selectAndAdd();

        await wrapper.setProps({ visible: false });

        expect(findError().exists()).toBe(false);
      });
    });

    describe('when the mutation request fails', () => {
      const error = new Error('Network error');

      it('shows a generic error in the modal and reports it', async () => {
        jest.spyOn(Sentry, 'captureException');
        createComponent({ mutationHandler: jest.fn().mockRejectedValue(error) });

        await selectAndAdd();

        expect(findError().text()).toBe('Something went wrong while linking the work item.');
        expect(wrapper.emitted('linked')).toBeUndefined();
        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });
  });
});
