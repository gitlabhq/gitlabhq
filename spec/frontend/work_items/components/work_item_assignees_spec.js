import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import { sortNameAlphabetically } from '~/work_items/utils';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import groupUsersSearchQuery from '~/graphql_shared/queries/group_users_search.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  projectMembersAutocompleteResponseWithCurrentUser,
  mockAssignees,
  currentUserResponse,
  currentUserNullResponse,
  updateWorkItemMutationResponse,
  projectMembersAutocompleteResponseWithNoMatchingUsers,
} from 'jest/work_items/mock_data';
import { i18n, TRACKING_CATEGORY_SHOW } from '~/work_items/constants';

const workItemId = 'gid://gitlab/WorkItem/1';

describe('WorkItemAssignees component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findInviteMembersTrigger = () => wrapper.findComponent(InviteMembersTrigger);
  const findAssignSelfButton = () => wrapper.findByTestId('assign-self');
  const findSidebarDropdownWidget = () => wrapper.findComponent(WorkItemSidebarDropdownWidget);
  const findAssigneeList = () => wrapper.findComponent(UncollapsedAssigneeList);

  const successSearchQueryHandler = jest
    .fn()
    .mockResolvedValue(projectMembersAutocompleteResponseWithCurrentUser);
  const successGroupSearchQueryHandler = jest
    .fn()
    .mockResolvedValue(projectMembersAutocompleteResponseWithCurrentUser);
  const successCurrentUserQueryHandler = jest.fn().mockResolvedValue(currentUserResponse);
  const noCurrentUserQueryHandler = jest.fn().mockResolvedValue(currentUserNullResponse);
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);
  const successSearchWithNoMatchingUsers = jest
    .fn()
    .mockResolvedValue(projectMembersAutocompleteResponseWithNoMatchingUsers);

  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const showDropdown = () => {
    findSidebarDropdownWidget().vm.$emit('dropdownShown');
  };

  const hideDropdown = () => {
    findSidebarDropdownWidget().vm.$emit('dropdownHidden');
  };

  const createComponent = ({
    mountFn = shallowMountExtended,
    assignees = mockAssignees,
    searchQueryHandler = successSearchQueryHandler,
    currentUserQueryHandler = successCurrentUserQueryHandler,
    allowsMultipleAssignees = false,
    canInviteMembers = false,
    canUpdate = true,
  } = {}) => {
    const apolloProvider = createMockApollo([
      [usersSearchQuery, searchQueryHandler],
      [groupUsersSearchQuery, successGroupSearchQueryHandler],
      [currentUserQuery, currentUserQueryHandler],
      [updateWorkItemMutation, successUpdateWorkItemMutationHandler],
    ]);

    wrapper = mountFn(WorkItemAssignees, {
      propsData: {
        assignees,
        fullPath: 'test-project-path',
        workItemId,
        allowsMultipleAssignees,
        workItemType: 'Task',
        canUpdate,
        canInviteMembers,
        isGroup: false,
      },
      apolloProvider,
    });
  };

  it('has "Assignee" label for single select', () => {
    createComponent();

    expect(findSidebarDropdownWidget().props('dropdownLabel')).toBe('Assignee');
  });

  describe('Dropdown search', () => {
    it('shows no items in the dropdown when no results matching', async () => {
      createComponent({ searchQueryHandler: successSearchWithNoMatchingUsers });
      showDropdown();
      await waitForPromises();

      expect(findSidebarDropdownWidget().props('listItems')).toEqual([]);
    });

    it('emits error event if search users query fails', async () => {
      createComponent({ searchQueryHandler: errorHandler });
      showDropdown();
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[i18n.fetchError]]);
    });

    it('clears search text on item select', () => {
      createComponent();

      expect(findSidebarDropdownWidget().props('clearSearchOnItemSelect')).toBe(true);
    });
  });

  describe('when assigning to current user', () => {
    it('does not show `Assign yourself` button if current user is loading', () => {
      createComponent();

      expect(findAssignSelfButton().exists()).toBe(false);
    });

    it('does now show `Assign yourself` button if user is not logged in', async () => {
      createComponent({ currentUserQueryHandler: noCurrentUserQueryHandler, assignees: [] });
      await waitForPromises();

      expect(findAssignSelfButton().exists()).toBe(false);
    });
  });

  describe('Dropdown options', () => {
    beforeEach(() => {
      createComponent({ canUpdate: true });
    });

    it('calls successSearchQueryHandler with variables when dropdown is opened', async () => {
      showDropdown();

      await waitForPromises();

      expect(successSearchQueryHandler).toHaveBeenCalledWith({
        isProject: true,
        fullPath: 'test-project-path',
        search: '',
      });
    });

    it('shows the skeleton loader when the items are being fetched on click', async () => {
      showDropdown();

      await nextTick();

      expect(findSidebarDropdownWidget().props('loading')).toBe(true);
    });

    it('shows the assignees in dropdown when the items have finished fetching', async () => {
      showDropdown();

      await waitForPromises();

      expect(findSidebarDropdownWidget().props('loading')).toBe(false);
      expect(findSidebarDropdownWidget().props('listItems')).toHaveLength(
        projectMembersAutocompleteResponseWithCurrentUser.data.workspace.users.length,
      );
    });
  });

  describe('when user is logged in and there are no assignees', () => {
    beforeEach(() => {
      createComponent({ assignees: [] });
      return waitForPromises();
    });

    it('renders `Assign yourself` button', () => {
      expect(findAssignSelfButton().exists()).toBe(true);
    });

    it('calls update work item assignees mutation with current user as a variable on button click', async () => {
      const { currentUser } = currentUserResponse.data;
      findAssignSelfButton().vm.$emit('click', new MouseEvent('click'));
      await nextTick();

      expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith({
        input: {
          id: workItemId,
          assigneesWidget: {
            assigneeIds: [currentUser.id],
          },
        },
      });
    });
  });

  describe('when multiple assignees are allowed', () => {
    beforeEach(() => {
      createComponent({ allowsMultipleAssignees: true, assignees: [] });
      return waitForPromises();
    });

    it('renders `Assignees` as label and `Select assignees` as dropdown button header', () => {
      expect(findSidebarDropdownWidget().props()).toMatchObject({
        dropdownLabel: 'Assignees',
        headerText: 'Select assignees',
      });
    });

    it('adds multiple assignees when collapsible listbox provides multiple values', async () => {
      showDropdown();
      await waitForPromises();

      findSidebarDropdownWidget().vm.$emit('updateValue', [
        'gid://gitlab/User/5',
        'gid://gitlab/User/6',
      ]);
      await nextTick();

      expect(findSidebarDropdownWidget().props('itemValue')).toHaveLength(2);
    });
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      trackingSpy = null;
    });

    it('tracks editing the assignees on dropdown widget updateValue', async () => {
      showDropdown();
      await waitForPromises();

      findSidebarDropdownWidget().vm.$emit('updateValue', mockAssignees[0].id);
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_assignees', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_assignees',
        property: 'type_Task',
      });
    });
  });

  describe('sorting', () => {
    it('sorts assignees based on alphabetical order on the frontend', async () => {
      createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(findAssigneeList().exists()).toBe(true);
      expect(findAssigneeList().props('users')).toHaveLength(mockAssignees.length);
      expect(findAssigneeList().props('users')).toStrictEqual(
        mockAssignees.sort(sortNameAlphabetically),
      );
    });

    it('sorts selected assignees first', async () => {
      const [unselected, selected] =
        projectMembersAutocompleteResponseWithCurrentUser.data.workspace.users;

      createComponent({
        assignees: [selected],
      });
      showDropdown();
      await waitForPromises();

      expect(findSidebarDropdownWidget().props('listItems')).toMatchObject(
        cloneDeep([
          { options: [selected], text: 'Selected' },
          { options: [unselected], text: 'All users', textSrOnly: true },
        ]),
      );
    });

    it('shows current user above other users', async () => {
      const [unselected, currentUser] = cloneDeep(
        projectMembersAutocompleteResponseWithCurrentUser.data.workspace.users,
      );

      createComponent({
        assignees: [],
      });
      showDropdown();
      await waitForPromises();

      findSidebarDropdownWidget().vm.$emit('updateValue', currentUser.id);

      expect(findSidebarDropdownWidget().props('listItems')).toMatchObject([
        { text: currentUser.name },
        { text: unselected.name },
      ]);
    });

    it('does not move newly selected assignees to the top until dropdown is closed', async () => {
      const [unselected, currentUser] = cloneDeep(
        projectMembersAutocompleteResponseWithCurrentUser.data.workspace.users,
      );

      createComponent({
        assignees: [],
      });
      showDropdown();
      await waitForPromises();

      findSidebarDropdownWidget().vm.$emit('updateValue', currentUser.id);

      expect(findSidebarDropdownWidget().props('listItems')).toMatchObject([
        { text: currentUser.name },
        { text: unselected.name },
      ]);

      hideDropdown();
      await waitForPromises();
      showDropdown();
      await waitForPromises();

      expect(findSidebarDropdownWidget().props('listItems')).toMatchObject([
        { options: [currentUser], text: 'Selected' },
        { options: [unselected], text: 'All users', textSrOnly: true },
      ]);
    });
  });

  describe('invite members', () => {
    it('does not render `Invite members` link if user has no permission to invite members', () => {
      createComponent();

      expect(findSidebarDropdownWidget().props('showFooter')).toBe(false);
      expect(findInviteMembersTrigger().exists()).toBe(false);
    });

    it('renders `Invite members` link if user has a permission to invite members', () => {
      createComponent({ canInviteMembers: true });

      expect(findSidebarDropdownWidget().props('showFooter')).toBe(true);
      expect(findInviteMembersTrigger().exists()).toBe(true);
    });
  });
});
