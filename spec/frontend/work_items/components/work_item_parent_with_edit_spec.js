import { GlForm, GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WorkItemParent from '~/work_items/components/work_item_parent_with_edit.vue';
import { removeHierarchyChild } from '~/work_items/graphql/cache_utils';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import groupWorkItemsQuery from '~/work_items/graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import { WORK_ITEM_TYPE_ENUM_OBJECTIVE } from '~/work_items/constants';

import {
  availableObjectivesResponse,
  mockParentWidgetResponse,
  updateWorkItemMutationResponseFactory,
  searchedObjectiveResponse,
  updateWorkItemMutationErrorResponse,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/work_items/graphql/cache_utils', () => ({
  removeHierarchyChild: jest.fn(),
}));

describe('WorkItemParent component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Objective';
  const mockFullPath = 'full-path';

  const groupWorkItemsSuccessHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const availableWorkItemsSuccessHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const availableWorkItemsFailureHandler = jest.fn().mockRejectedValue(new Error());

  const findHeader = () => wrapper.find('h3');
  const findEditButton = () => wrapper.find('[data-testid="edit-parent"]');
  const findApplyButton = () => wrapper.find('[data-testid="apply-parent"]');

  const findLoadingIcon = () => wrapper.find('[data-testid="loading-icon-parent"]');
  const findLabel = () => wrapper.find('label');
  const findForm = () => wrapper.findComponent(GlForm);
  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ parent: mockParentWidgetResponse }));

  const createComponent = ({
    canUpdate = true,
    parent = null,
    searchQueryHandler = availableWorkItemsSuccessHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
    isEditing = false,
    isGroup = false,
  } = {}) => {
    wrapper = mountExtended(WorkItemParent, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, searchQueryHandler],
        [groupWorkItemsQuery, groupWorkItemsSuccessHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      provide: {
        fullPath: mockFullPath,
        isGroup,
      },
      propsData: {
        canUpdate,
        parent,
        workItemId,
        workItemType,
      },
    });

    if (isEditing) {
      findEditButton().trigger('click');
    }
  };

  beforeEach(() => {
    createComponent();
  });

  describe('label', () => {
    it('shows header when not editing', () => {
      createComponent();

      expect(findHeader().exists()).toBe(true);
      expect(findHeader().classes('gl-sr-only')).toBe(false);
      expect(findLabel().exists()).toBe(false);
    });

    it('shows label and hides header while editing', async () => {
      createComponent({ isEditing: true });

      await nextTick();

      expect(findLabel().exists()).toBe(true);
      expect(findHeader().classes('gl-sr-only')).toBe(true);
    });
  });

  describe('edit button', () => {
    it('is not shown if user cannot edit', () => {
      createComponent({ canUpdate: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('is shown if user can edit', () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('triggers edit mode on click', async () => {
      createComponent();

      findEditButton().trigger('click');

      await nextTick();

      expect(findLabel().exists()).toBe(true);
      expect(findForm().exists()).toBe(true);
    });

    it('is replaced by Apply button while editing', async () => {
      createComponent();

      findEditButton().trigger('click');

      await nextTick();

      expect(findEditButton().exists()).toBe(false);
      expect(findApplyButton().exists()).toBe(true);
    });
  });

  describe('loading icon', () => {
    const selectWorkItem = async (workItem) => {
      await findCollapsibleListbox().vm.$emit('select', workItem);
    };

    it('shows loading icon while update is in progress', async () => {
      createComponent();
      findEditButton().trigger('click');

      await nextTick();

      selectWorkItem('gid://gitlab/WorkItem/716');

      await nextTick();
      expect(findLoadingIcon().exists()).toBe(true);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows loading icon when unassign is clicked', async () => {
      createComponent({ parent: mockParentWidgetResponse });
      findEditButton().trigger('click');

      await nextTick();

      findCollapsibleListbox().vm.$emit('reset');

      await nextTick();
      expect(findLoadingIcon().exists()).toBe(true);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('value', () => {
    it('shows None when no parent is set', () => {
      createComponent();

      expect(wrapper.text()).toContain(__('None'));
    });

    it('shows parent when parent is set', () => {
      createComponent({ parent: mockParentWidgetResponse });

      expect(wrapper.text()).not.toContain(__('None'));
      expect(wrapper.text()).toContain(mockParentWidgetResponse.title);
    });
  });

  describe('form', () => {
    it('is not shown while not editing', async () => {
      await createComponent();

      expect(findForm().exists()).toBe(false);
    });

    it('is shown while editing', async () => {
      await createComponent({ isEditing: true });

      expect(findForm().exists()).toBe(true);
    });
  });

  describe('Parent Input', () => {
    it('is not shown while not editing', async () => {
      await createComponent();

      expect(findCollapsibleListbox().exists()).toBe(false);
    });

    it('renders the collapsible listbox with required props', async () => {
      await createComponent({ isEditing: true });

      expect(findCollapsibleListbox().exists()).toBe(true);
      expect(findCollapsibleListbox().props()).toMatchObject({
        items: [],
        headerText: 'Assign parent',
        category: 'primary',
        loading: false,
        isCheckCentered: true,
        searchable: true,
        searching: false,
        infiniteScroll: false,
        noResultsText: 'No matching results',
        toggleText: 'None',
        searchPlaceholder: 'Search',
        resetButtonLabel: 'Unassign',
      });
    });
    it('shows loading while searching', async () => {
      await createComponent({ isEditing: true });

      await findCollapsibleListbox().vm.$emit('shown');
      expect(findCollapsibleListbox().props('searching')).toBe(true);
    });
  });

  describe('work items query', () => {
    it('loads work items in the listbox', async () => {
      await createComponent({ isEditing: true });
      await findCollapsibleListbox().vm.$emit('shown');

      await waitForPromises();

      expect(findCollapsibleListbox().props('searching')).toBe(false);
      expect(findCollapsibleListbox().props('items')).toStrictEqual([
        { text: 'Objective 101', value: 'gid://gitlab/WorkItem/716' },
        { text: 'Objective 103', value: 'gid://gitlab/WorkItem/712' },
        { text: 'Objective 102', value: 'gid://gitlab/WorkItem/711' },
      ]);
      expect(availableWorkItemsSuccessHandler).toHaveBeenCalled();
    });

    it('emits error when the query fails', async () => {
      await createComponent({
        searchQueryHandler: availableWorkItemsFailureHandler,
        isEditing: true,
      });

      await findCollapsibleListbox().vm.$emit('shown');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while fetching items. Please try again.'],
      ]);
    });

    it('searches item when input data is entered', async () => {
      const searchedItemQueryHandler = jest.fn().mockResolvedValue(searchedObjectiveResponse);
      await createComponent({
        searchQueryHandler: searchedItemQueryHandler,
        isEditing: true,
      });

      await findCollapsibleListbox().vm.$emit('shown');

      await waitForPromises();

      expect(searchedItemQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full-path',
        searchTerm: '',
        types: [WORK_ITEM_TYPE_ENUM_OBJECTIVE],
        in: undefined,
        iid: null,
        isNumber: false,
        searchByIid: false,
        searchByText: true,
      });

      await findCollapsibleListbox().vm.$emit('search', 'Objective 101');

      expect(searchedItemQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full-path',
        searchTerm: 'Objective 101',
        types: [WORK_ITEM_TYPE_ENUM_OBJECTIVE],
        in: 'TITLE',
        iid: null,
        isNumber: false,
        searchByIid: false,
        searchByText: true,
      });

      await nextTick();

      expect(findCollapsibleListbox().props('items')).toStrictEqual([
        { text: 'Objective 101', value: 'gid://gitlab/WorkItem/716' },
      ]);
    });
  });

  describe('listbox', () => {
    const selectWorkItem = async (workItem) => {
      await findCollapsibleListbox().vm.$emit('select', workItem);
    };

    it('calls mutation when item is selected', async () => {
      await createComponent({ isEditing: true });
      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          hierarchyWidget: {
            parentId: 'gid://gitlab/WorkItem/716',
          },
        },
      });

      expect(removeHierarchyChild).toHaveBeenCalledWith({
        cache: expect.anything(Object),
        fullPath: mockFullPath,
        iid: undefined,
        isGroup: false,
        workItem: { id: 'gid://gitlab/WorkItem/1' },
      });
    });

    it('calls mutation when item is unassigned', async () => {
      const unAssignParentWorkItemMutationHandler = jest
        .fn()
        .mockResolvedValue(updateWorkItemMutationResponseFactory({ parent: null }));
      await createComponent({
        parent: {
          iid: '1',
        },
        mutationHandler: unAssignParentWorkItemMutationHandler,
      });

      findEditButton().trigger('click');

      await nextTick();

      findCollapsibleListbox().vm.$emit('reset');

      await waitForPromises();

      expect(unAssignParentWorkItemMutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          hierarchyWidget: {
            parentId: null,
          },
        },
      });
      expect(removeHierarchyChild).toHaveBeenCalledWith({
        cache: expect.anything(Object),
        fullPath: mockFullPath,
        iid: '1',
        isGroup: false,
        workItem: { id: 'gid://gitlab/WorkItem/1' },
      });
    });

    it('emits error when mutation fails', async () => {
      await createComponent({
        mutationHandler: jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse),
        isEditing: true,
      });

      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Error!']]);
    });

    it('emits error and captures exception in sentry when network request fails', async () => {
      const error = new Error('error');
      await createComponent({
        mutationHandler: jest.fn().mockRejectedValue(error),
        isEditing: true,
      });

      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the objective. Please try again.'],
      ]);
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});
