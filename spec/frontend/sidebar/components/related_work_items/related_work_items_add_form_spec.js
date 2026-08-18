import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlCollapsibleListbox, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import RelatedWorkItemsAddForm from '~/sidebar/components/related_work_items/related_work_items_add_form.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import recentlyViewedWorkItemsQuery from '~/sidebar/queries/recently_viewed_work_items.query.graphql';
import { MR_WORK_ITEM_RELATIONSHIP_OPTIONS } from '~/sidebar/constants';

jest.mock('~/alert');

Vue.use(VueApollo);

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

describe('RelatedWorkItemsAddForm', () => {
  let wrapper;

  const findRecentItems = () => wrapper.findAllByTestId('recently-viewed-item');
  const findRelationshipListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findTokenInput = () => wrapper.findComponent(WorkItemTokenInput);
  const findCreateModal = () => wrapper.findComponent(CreateWorkItemModal);
  const findCreateButton = () => wrapper.findComponentByTestId('add-work-item-create');
  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({
    queryHandler = jest
      .fn()
      .mockResolvedValue(recentlyViewedResponse([issueItem, issueItemWithoutIcon])),
    propsData = {},
  } = {}) => {
    wrapper = shallowMountExtended(RelatedWorkItemsAddForm, {
      apolloProvider: createMockApollo([[recentlyViewedWorkItemsQuery, queryHandler]]),
      propsData: {
        fullPath: 'group/project',
        mergeRequestId: 'gid://gitlab/MergeRequest/1',
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
      createComponent();
      await findRelationshipListbox().vm.$emit('select', 'RELATED');

      findCreateModal().vm.$emit('work-item-created', createdWorkItem);

      expect(wrapper.emitted('created')).toEqual([
        [{ workItem: createdWorkItem, linkType: 'RELATED' }],
      ]);
      expect(wrapper.emitted('link')).toBeUndefined();
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
});
