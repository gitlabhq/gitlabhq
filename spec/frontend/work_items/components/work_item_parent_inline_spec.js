import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WorkItemParentInline from '~/work_items/components/work_item_parent_inline.vue';
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

describe('WorkItemParentInline component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Objective';
  const mockFullPath = 'full-path';

  const groupWorkItemsSuccessHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const availableWorkItemsSuccessHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const availableWorkItemsFailureHandler = jest.fn().mockRejectedValue(new Error());

  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ parent: mockParentWidgetResponse }));

  const createComponent = ({
    canUpdate = true,
    parent = null,
    searchQueryHandler = availableWorkItemsSuccessHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
    isGroup = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemParentInline, {
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
  };

  beforeEach(() => {
    createComponent();
  });

  const findInputGroup = () => wrapper.findComponent(GlFormGroup);
  const findParentText = () => wrapper.findByTestId('disabled-text');
  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('template', () => {
    it('shows field label as Parent', () => {
      expect(findInputGroup().exists()).toBe(true);
      expect(findInputGroup().attributes('label')).toBe('Parent');
    });

    it('renders the collapsible listbox with required props', () => {
      expect(findCollapsibleListbox().exists()).toBe(true);
      expect(findCollapsibleListbox().props()).toMatchObject({
        items: [],
        headerText: 'Assign parent',
        category: 'tertiary',
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

    it('displays parent text instead of listbox if canUpdate is false', () => {
      createComponent({ canUpdate: false, parent: mockParentWidgetResponse });

      expect(findCollapsibleListbox().exists()).toBe(false);
      expect(findParentText().text()).toBe('Objective 101');
    });

    it('shows loading while searching', async () => {
      await findCollapsibleListbox().vm.$emit('shown');
      expect(findCollapsibleListbox().props('searching')).toBe(true);
    });
  });

  describe('work items query', () => {
    it('loads work items in the listbox', async () => {
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
      createComponent({ searchQueryHandler: availableWorkItemsFailureHandler });

      await findCollapsibleListbox().vm.$emit('shown');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while fetching items. Please try again.'],
      ]);
    });

    it('searches item when input data is entered', async () => {
      const searchedItemQueryHandler = jest.fn().mockResolvedValue(searchedObjectiveResponse);
      createComponent({
        searchQueryHandler: searchedItemQueryHandler,
      });

      await findCollapsibleListbox().vm.$emit('shown');

      await waitForPromises();

      expect(searchedItemQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full-path',
        searchTerm: '',
        types: [WORK_ITEM_TYPE_ENUM_OBJECTIVE],
        in: undefined,
        iid: null,
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
      createComponent({
        parent: {
          iid: '1',
        },
        mutationHandler: unAssignParentWorkItemMutationHandler,
      });

      await findCollapsibleListbox().vm.$emit('reset');

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
      createComponent({
        mutationHandler: jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse),
      });

      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Error!']]);
    });

    it('emits error and captures exception in sentry when network request fails', async () => {
      const error = new Error('error');
      createComponent({
        mutationHandler: jest.fn().mockRejectedValue(error),
      });

      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the objective. Please try again.'],
      ]);
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('when project context', () => {
    beforeEach(() => {
      createComponent();
      findCollapsibleListbox().vm.$emit('shown');
    });

    it('calls the project work items query', () => {
      expect(availableWorkItemsSuccessHandler).toHaveBeenCalled();
    });

    it('skips calling the group work items query', () => {
      expect(groupWorkItemsSuccessHandler).not.toHaveBeenCalled();
    });
  });

  describe('when group context', () => {
    beforeEach(() => {
      createComponent({ isGroup: true });
      findCollapsibleListbox().vm.$emit('shown');
    });

    it('skips calling the project work items query', () => {
      expect(availableWorkItemsSuccessHandler).not.toHaveBeenCalled();
    });

    it('calls the group work items query', () => {
      expect(groupWorkItemsSuccessHandler).toHaveBeenCalled();
    });
  });
});
