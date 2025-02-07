import { GlPopover } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WorkItemParent from '~/work_items/components/work_item_parent.vue';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import { updateParent } from '~/work_items/graphql/cache_utils';
import updateWorkItemMutation from '~/work_items/graphql/update_parent.mutation.graphql';
import groupWorkItemsQuery from '~/work_items/graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '~/work_items/graphql/work_items_by_references.query.graphql';
import getAllowedWorkItemParentTypes from '~/work_items/graphql/work_item_allowed_parent_types.query.graphql';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';

import {
  availableObjectivesResponse,
  mockParentWidgetResponse,
  mockAncestorWidgetResponse,
  mockEmptyAncestorWidgetResponse,
  searchedObjectiveResponse,
  updateWorkItemMutationErrorResponse,
  mockworkItemReferenceQueryResponse,
  allowedParentTypesResponse,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/work_items/graphql/cache_utils', () => ({
  updateParent: jest.fn(),
}));

describe('WorkItemParent component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Objective';
  const mockFullPath = 'full-path';

  const groupWorkItemsSuccessHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const availableWorkItemsSuccessHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const failedQueryHandler = jest.fn().mockRejectedValue(new Error());
  const allowedParentTypesHandler = jest.fn().mockResolvedValue(allowedParentTypesResponse);

  const workItemReferencesSuccessHandler = jest
    .fn()
    .mockResolvedValue(mockworkItemReferenceQueryResponse);

  const findSidebarDropdownWidget = () => wrapper.findComponent(WorkItemSidebarDropdownWidget);
  const findAncestorUnavailable = () => wrapper.findByTestId('ancestor-not-available');
  const findPopover = () => wrapper.findComponent(GlPopover);

  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(mockAncestorWidgetResponse);

  const showDropdown = () => {
    findSidebarDropdownWidget().vm.$emit('dropdownShown');
  };

  const createComponent = ({
    canUpdate = true,
    parent = null,
    searchQueryHandler = availableWorkItemsSuccessHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
    hasParent = true,
  } = {}) => {
    wrapper = mountExtended(WorkItemParent, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, searchQueryHandler],
        [groupWorkItemsQuery, groupWorkItemsSuccessHandler],
        [updateWorkItemMutation, mutationHandler],
        [workItemsByReferencesQuery, workItemReferencesSuccessHandler],
        [getAllowedWorkItemParentTypes, allowedParentTypesHandler],
      ]),
      provide: {
        fullPath: mockFullPath,
      },
      propsData: {
        canUpdate,
        parent,
        workItemId,
        workItemType,
        hasParent,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when loaded', () => {
    it('fetches allowed parent types for the current work item', async () => {
      createComponent();
      await waitForPromises();

      expect(allowedParentTypesHandler).toHaveBeenCalled();
    });
  });

  describe('label', () => {
    it('shows widget label', () => {
      createComponent();

      expect(findSidebarDropdownWidget().props('dropdownLabel')).toBe('Parent');
    });
  });

  describe('edit button', () => {
    it('is not shown if user cannot edit', () => {
      createComponent({ canUpdate: false });

      expect(findSidebarDropdownWidget().props('canUpdate')).toBe(false);
    });

    it('is shown if user can edit', () => {
      createComponent({ canUpdate: true });

      expect(findSidebarDropdownWidget().props('canUpdate')).toBe(true);
    });

    it('fetches the  work items on edit click', async () => {
      createComponent();

      showDropdown();

      await nextTick();

      expect(findSidebarDropdownWidget().props('loading')).toBe(true);
      await waitForPromises();
      expect(availableWorkItemsSuccessHandler).toHaveBeenCalled();
    });
  });

  describe('loading icon', () => {
    const selectWorkItem = (workItem) => {
      findSidebarDropdownWidget().vm.$emit('updateValue', workItem);
    };

    it('shows loading icon while update is in progress', async () => {
      createComponent();
      showDropdown();

      await waitForPromises();

      selectWorkItem('gid://gitlab/WorkItem/716');

      await nextTick();

      expect(findSidebarDropdownWidget().props('updateInProgress')).toBe(true);
      await waitForPromises();

      expect(findSidebarDropdownWidget().props('updateInProgress')).toBe(false);
    });

    it('shows loading icon when unassign is clicked', async () => {
      createComponent({ parent: mockEmptyAncestorWidgetResponse });
      showDropdown();

      await waitForPromises();

      findSidebarDropdownWidget().vm.$emit('reset');

      await nextTick();

      expect(findSidebarDropdownWidget().props('updateInProgress')).toBe(true);
      await waitForPromises();

      expect(findSidebarDropdownWidget().props('updateInProgress')).toBe(false);
    });
  });

  describe('value', () => {
    beforeEach(() => {
      createComponent({ parent: mockParentWidgetResponse });
    });

    it('shows None when no parent is set', () => {
      createComponent({ hasParent: false });

      expect(wrapper.text()).toContain('None');
    });

    it('shows parent when parent is set', () => {
      expect(wrapper.text()).not.toContain('None');
      expect(wrapper.text()).toContain(mockParentWidgetResponse.title);
    });

    it('does not show ancestor not available message', () => {
      expect(findAncestorUnavailable().exists()).toBe(false);
    });

    it('does not render inaccessible parent popover', () => {
      expect(findPopover().exists()).toBe(false);
    });
  });

  describe('Parent dropdown', () => {
    it('renders the sidebar dropdwon widget with required props by default', () => {
      createComponent();

      expect(findSidebarDropdownWidget().exists()).toBe(true);
      expect(findSidebarDropdownWidget().props()).toMatchObject({
        listItems: [],
        headerText: 'Select parent',
        loading: false,
        searchable: true,
        infiniteScroll: false,
        resetButtonLabel: 'Clear',
      });
    });

    it('shows loading while searching', async () => {
      createComponent();

      showDropdown();

      await nextTick();
      expect(findSidebarDropdownWidget().props('loading')).toBe(true);
    });
  });

  describe('work items query', () => {
    const mockText = 'Objective 101';
    const mockURL = 'http://localhost/gitlab-org/test-project-path/-/work_items/111';
    const mockReference = 'gitlab-org/test-project-path#111';

    it('loads work items in the listbox', async () => {
      createComponent();
      showDropdown();

      await waitForPromises();

      expect(findSidebarDropdownWidget().props('loading')).toBe(false);
      expect(findSidebarDropdownWidget().props('listItems')).toStrictEqual([
        { text: 'Objective 101', value: 'gid://gitlab/WorkItem/716' },
        { text: 'Objective 103', value: 'gid://gitlab/WorkItem/712' },
        { text: 'Objective 102', value: 'gid://gitlab/WorkItem/711' },
      ]);
      expect(availableWorkItemsSuccessHandler).toHaveBeenCalled();
    });

    it('emits error when the query fails', async () => {
      createComponent({
        searchQueryHandler: failedQueryHandler,
      });

      showDropdown();

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while fetching items. Please try again.'],
      ]);
    });

    it('skips the work item query when the getAllowedWorkItemParentTypes query fails', async () => {
      createComponent({
        allowedParentTypesHandler: failedQueryHandler,
      });
      await waitForPromises();

      expect(availableWorkItemsSuccessHandler).not.toHaveBeenCalled();
    });

    it('searches item when input data is entered', async () => {
      const searchedItemQueryHandler = jest.fn().mockResolvedValue(searchedObjectiveResponse);
      createComponent({
        searchQueryHandler: searchedItemQueryHandler,
      });

      showDropdown();

      await waitForPromises();

      expect(searchedItemQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full-path',
        searchTerm: '',
        types: [WORK_ITEM_TYPE_ENUM_EPIC],
        in: undefined,
        iid: null,
        isNumber: false,
        searchByIid: false,
        searchByText: true,
        includeAncestors: true,
      });

      findSidebarDropdownWidget().vm.$emit('searchStarted', mockText);

      await waitForPromises();

      expect(searchedItemQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full-path',
        searchTerm: mockText,
        types: [WORK_ITEM_TYPE_ENUM_EPIC],
        in: 'TITLE',
        iid: null,
        isNumber: false,
        searchByIid: false,
        searchByText: true,
        includeAncestors: true,
      });
      expect(workItemReferencesSuccessHandler).not.toHaveBeenCalled();

      await nextTick();

      expect(findSidebarDropdownWidget().props('listItems')).toStrictEqual([
        { text: mockText, value: 'gid://gitlab/WorkItem/716' },
      ]);
    });

    it.each`
      inputType      | input            | refs
      ${'url'}       | ${mockURL}       | ${[mockURL]}
      ${'reference'} | ${mockReference} | ${[mockReference]}
    `('lists work item when valid $inputType is pasted', async ({ input, refs }) => {
      createComponent();

      showDropdown();

      await waitForPromises();

      expect(availableWorkItemsSuccessHandler).toHaveBeenCalledWith({
        fullPath: mockFullPath,
        searchTerm: '',
        types: [WORK_ITEM_TYPE_ENUM_EPIC],
        in: undefined,
        iid: null,
        isNumber: false,
        searchByIid: false,
        searchByText: true,
        includeAncestors: true,
      });

      findSidebarDropdownWidget().vm.$emit('searchStarted', input);

      await waitForPromises();

      expect(workItemReferencesSuccessHandler).toHaveBeenCalledWith({
        contextNamespacePath: mockFullPath,
        refs,
      });

      await nextTick();

      expect(findSidebarDropdownWidget().props('listItems')).toStrictEqual([
        { text: 'Objective linked items 104', value: 'gid://gitlab/WorkItem/705' },
      ]);
    });
  });

  describe('listbox', () => {
    const selectWorkItem = (workItem) => {
      findSidebarDropdownWidget().vm.$emit('updateValue', workItem);
    };

    it('calls mutation when item is selected', async () => {
      createComponent();

      showDropdown();
      await waitForPromises();

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

      expect(updateParent).toHaveBeenCalledWith({
        cache: expect.anything(Object),
        fullPath: mockFullPath,
        iid: undefined,
        workItem: { id: 'gid://gitlab/WorkItem/1' },
      });
    });

    it('calls mutation when item is unassigned', async () => {
      const unAssignParentWorkItemMutationHandler = jest
        .fn()
        .mockResolvedValue(mockEmptyAncestorWidgetResponse);
      createComponent({
        parent: {
          iid: '1',
        },
        mutationHandler: unAssignParentWorkItemMutationHandler,
      });

      showDropdown();
      await waitForPromises();

      findSidebarDropdownWidget().vm.$emit('reset');

      await waitForPromises();

      expect(unAssignParentWorkItemMutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          hierarchyWidget: {
            parentId: null,
          },
        },
      });
      expect(updateParent).toHaveBeenCalledWith({
        cache: expect.anything(Object),
        fullPath: mockFullPath,
        iid: '1',
        workItem: { id: 'gid://gitlab/WorkItem/1' },
      });
    });

    it('emits error when mutation fails', async () => {
      createComponent({
        mutationHandler: jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse),
      });

      showDropdown();
      await waitForPromises();

      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Error!']]);
    });

    it('emits error and captures exception in sentry when network request fails', async () => {
      const error = new Error('error');
      createComponent({
        mutationHandler: jest.fn().mockRejectedValue(error),
      });

      showDropdown();
      await waitForPromises();

      selectWorkItem('gid://gitlab/WorkItem/716');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the objective. Please try again.'],
      ]);
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('with inaccessible parent', () => {
    beforeEach(() => {
      createComponent({ hasParent: true });
    });

    it('shows ancestor not available message', () => {
      expect(findAncestorUnavailable().exists()).toBe(true);
      expect(findAncestorUnavailable().text()).toBe('Ancestor not available');
    });

    it('displays appropriate message in popover on hover and focus', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().props('triggers')).toBe('hover focus');
      expect(findPopover().text()).toEqual(
        `You don't have the necessary permission to view the ancestor.`,
      );
    });
  });
});
