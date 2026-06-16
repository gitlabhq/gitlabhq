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
      recentlyViewedItems: items,
      __typename: 'CurrentUser',
    },
  },
});

const workItemEntry = {
  viewedAt: '2024-01-01T00:00:00Z',
  item: {
    id: 'gid://gitlab/WorkItem/1',
    title: 'A recently viewed task',
    webUrl: '/group/project/-/work_items/1',
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/1',
      name: 'Task',
      iconName: 'work-item-task',
      __typename: 'WorkItemType',
    },
    __typename: 'WorkItem',
  },
};

const issueEntry = {
  viewedAt: '2024-01-02T00:00:00Z',
  item: {
    id: 'gid://gitlab/Issue/2',
    title: 'A recently viewed issue',
    webUrl: '/group/project/-/issues/2',
    workItemType: {
      id: 'gid://gitlab/WorkItems::Type/2',
      name: 'Issue',
      iconName: null,
      __typename: 'WorkItemType',
    },
    __typename: 'Issue',
  },
};

describe('RelatedWorkItemsAddForm', () => {
  let wrapper;

  const findRecentItems = () => wrapper.findAllByTestId('recently-viewed-item');
  const findRelationshipListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findTokenInput = () => wrapper.findComponent(WorkItemTokenInput);
  const findCreateModal = () => wrapper.findComponent(CreateWorkItemModal);
  const findCreateButton = () => wrapper.findByTestId('add-work-item-create');
  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({
    queryHandler = jest.fn().mockResolvedValue(recentlyViewedResponse([workItemEntry, issueEntry])),
    propsData = {},
  } = {}) => {
    wrapper = shallowMountExtended(RelatedWorkItemsAddForm, {
      apolloProvider: createMockApollo([[recentlyViewedWorkItemsQuery, queryHandler]]),
      propsData: {
        fullPath: 'group/project',
        visible: true,
        ...propsData,
      },
    });
  };

  it('fetches the current user recently viewed items', async () => {
    const queryHandler = jest.fn().mockResolvedValue(recentlyViewedResponse([workItemEntry]));
    createComponent({ queryHandler });
    await waitForPromises();

    expect(queryHandler).toHaveBeenCalledTimes(1);
  });

  it('renders a row for each fetched recently viewed item', async () => {
    createComponent();
    await waitForPromises();

    expect(findRecentItems()).toHaveLength(2);
    expect(findRecentItems().at(0).text()).toContain('A recently viewed task');
    expect(findRecentItems().at(1).text()).toContain('A recently viewed issue');
  });

  it('maps a work item to its type icon and an issue to the default issue icon', async () => {
    createComponent();
    await waitForPromises();

    const icons = wrapper.findAllComponents(GlIcon);
    expect(icons.at(0).props('name')).toBe('work-item-task');
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
  });
});
