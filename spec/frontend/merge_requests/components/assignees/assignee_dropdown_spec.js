import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { createAlert } from '~/alert';
import AssigneeDropdown from '~/merge_requests/components/assignees/assignee_dropdown.vue';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';
import userAutocompleteWithMRPermissionsQuery from 'ee_else_ce/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import setAssigneesMutation from '~/sidebar/queries/update_mr_assignees.mutation.graphql';

jest.mock('~/alert');

Vue.use(VueApollo);

const createMockUser = ({
  id = 1,
  name = 'Administrator',
  username = 'root',
  canMerge = true,
  availability = 'NOT_SET',
  compositeIdentityEnforced = false,
} = {}) => ({
  __typename: 'UserCore',
  id: `gid://gitlab/User/${id}`,
  avatarUrl: '/avatar',
  webUrl: `/${username}`,
  webPath: `/${username}`,
  status: { availability },
  duoStatus: {
    disabled: false,
    disabledReason: null,
    flowTriggerEvents: [],
  },
  compositeIdentityEnforced,
  mergeRequestInteraction: {
    canMerge,
    applicableApprovalRules: [],
  },
  username,
  name,
});

const mockUser = createMockUser();
const mockOtherUser = createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' });
// An agent with no ASSIGN trigger is disabled by ~/ai/agents_utils
const mockDisabledUser = createMockUser({
  id: 4,
  name: 'Agent',
  username: 'agent',
  compositeIdentityEnforced: true,
});

describe('Assignee dropdown component', () => {
  let wrapper;
  let autocompleteUsersMock;
  let setAssigneesMutationMock;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findEditButton = () => wrapper.findByTestId('assignees-edit-button');
  const options = (groupIndex) => findDropdown().props('items')[groupIndex].options;
  const optionValues = (groupIndex) => options(groupIndex).map(({ value }) => value);

  const createComponent = ({
    propsData = {},
    users = [mockUser, mockOtherUser],
    autocompleteHandler = null,
    mutationHandler = null,
    directlyInviteMembers = false,
    mountFn = shallowMountExtended,
  } = {}) => {
    autocompleteUsersMock =
      autocompleteHandler ||
      jest.fn().mockResolvedValue({
        data: { namespace: { __typename: 'Project', id: '1', users } },
      });
    setAssigneesMutationMock =
      mutationHandler ||
      jest.fn().mockResolvedValue({
        data: {
          issuableSetAssignees: {
            errors: [],
            issuable: {
              __typename: 'MergeRequest',
              id: 'gid://gitlab/MergeRequest/1',
              assignees: { __typename: 'UserConnection', nodes: [] },
            },
          },
        },
      });

    wrapper = mountFn(AssigneeDropdown, {
      apolloProvider: createMockApollo([
        [userAutocompleteWithMRPermissionsQuery, autocompleteUsersMock],
        [setAssigneesMutation, setAssigneesMutationMock],
      ]),
      propsData: {
        fullPath: 'gitlab-org/gitlab',
        iid: '1',
        issuableId: 1,
        selectedAssignees: [],
        ...propsData,
      },
      provide: { directlyInviteMembers },
    });
  };

  const openDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await waitForPromises();
  };

  const closeDropdown = async () => {
    findDropdown().vm.$emit('hidden');
    await waitForPromises();
  };

  beforeEach(() => {
    gon.current_username = 'root';
    gon.current_user_fullname = 'Administrator';
    gon.current_user_avatar_url = '/root';
    gon.keyboard_shortcuts_enabled = true;
  });

  it('fetches the autocomplete users when the dropdown opens', async () => {
    createComponent();

    expect(autocompleteUsersMock).not.toHaveBeenCalled();

    await openDropdown();

    expect(autocompleteUsersMock).toHaveBeenCalledWith({
      search: '',
      fullPath: 'gitlab-org/gitlab',
      mergeRequestId: 'gid://gitlab/MergeRequest/1',
    });
    expect(optionValues(0)).toEqual(['root', 'bob']);
  });

  it('searches the autocomplete users with the search term', async () => {
    createComponent();
    await openDropdown();

    findDropdown().vm.$emit('search', 'bob');
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await waitForPromises();

    expect(autocompleteUsersMock).toHaveBeenCalledWith(expect.objectContaining({ search: 'bob' }));
  });

  it.each([
    ['fails', new Error('nope'), 1],
    ['is superseded and aborted', { name: 'AbortError' }, 0],
  ])('creates the right number of alerts when the fetch %s', async (_, rejection, alerts) => {
    createComponent({ autocompleteHandler: jest.fn().mockRejectedValue(rejection) });
    await openDropdown();

    expect(createAlert).toHaveBeenCalledTimes(alerts);
  });

  it('groups the selected assignees separately from the other users', async () => {
    createComponent({ propsData: { selectedAssignees: [mockUser] } });
    await openDropdown();

    expect(findDropdown().props('items')[0]).toMatchObject({ text: 'Assignees' });
    expect(optionValues(0)).toEqual(['root']);
    expect(optionValues(1)).toEqual(['bob']);
  });

  it('adds the author and the current user to the list when they are not members', async () => {
    const author = createMockUser({ id: 3, name: 'Author', username: 'author' });

    createComponent({ propsData: { author }, users: [mockOtherUser] });
    await openDropdown();

    expect(optionValues(0)).toEqual(['root', 'author', 'bob']);
  });

  it.each([
    [false, 'root', 'Unassign'],
    [true, ['root'], 'Unassign all'],
  ])(
    'binds the selection as the listbox expects when multiple is %s',
    (multipleSelectionEnabled, selected, resetButtonLabel) => {
      createComponent({ propsData: { selectedAssignees: [mockUser], multipleSelectionEnabled } });

      expect(findDropdown().props()).toMatchObject({
        multiple: multipleSelectionEnabled,
        selected,
        resetButtonLabel,
      });
    },
  );

  it('renders the status of each user', async () => {
    createComponent({
      users: [
        createMockUser({ id: 5, username: 'busy', availability: 'BUSY' }),
        createMockUser({ id: 6, username: 'nomerge', canMerge: false }),
        mockDisabledUser,
      ],
      mountFn: mountExtended,
    });
    await openDropdown();

    expect(wrapper.findByTestId('busy-badge').exists()).toBe(true);
    expect(wrapper.find('[aria-label="Cannot merge"]').exists()).toBe(true);
    expect(wrapper.text()).toContain('No triggers for this event');
  });

  it('renders the invite members trigger when members can be invited', async () => {
    createComponent({ directlyInviteMembers: true, mountFn: mountExtended });
    await openDropdown();

    expect(wrapper.findComponent(SidebarInviteMembers).exists()).toBe(true);
  });

  it('lets the keyboard shortcut open the dropdown', () => {
    createComponent({ mountFn: mountExtended });

    // shortcuts_issuable.js clicks `.block.assignee .shortcut-sidebar-dropdown-toggle`
    expect(findEditButton().classes()).toContain('shortcut-sidebar-dropdown-toggle');
    expect(findEditButton().attributes('aria-keyshortcuts')).toBe('a');
  });

  describe('when the dropdown closes', () => {
    it('sets the selected assignees', async () => {
      createComponent({ propsData: { multipleSelectionEnabled: true } });
      await openDropdown();

      findDropdown().vm.$emit('select', ['root', 'bob']);
      await closeDropdown();

      expect(setAssigneesMutationMock).toHaveBeenCalledWith({
        assigneeUsernames: ['root', 'bob'],
        fullPath: 'gitlab-org/gitlab',
        iid: '1',
      });
    });

    it('does not set the assignees when the selection is untouched', async () => {
      createComponent();
      await openDropdown();

      // The assignees load after the dropdown mounts, so the watcher has to reseed
      wrapper.setProps({ selectedAssignees: [mockUser] });
      await closeDropdown();

      expect(setAssigneesMutationMock).not.toHaveBeenCalled();
      expect(findDropdown().props('selected')).toBe('root');
    });

    it('unassigns all the users after a reset', async () => {
      createComponent({ propsData: { selectedAssignees: [mockUser] } });
      await openDropdown();

      findDropdown().vm.$emit('reset');
      await closeDropdown();

      expect(setAssigneesMutationMock).toHaveBeenCalledWith(
        expect.objectContaining({ assigneeUsernames: [] }),
      );
    });

    it.each([
      [
        'returns errors',
        jest.fn().mockResolvedValue({
          data: { issuableSetAssignees: { errors: ['Cannot assign the user.'], issuable: null } },
        }),
        'Cannot assign the user.',
      ],
      [
        'fails',
        jest.fn().mockRejectedValue(new Error('nope')),
        'An error occurred while updating assignees.',
      ],
    ])('restores the previous assignees when the mutation %s', async (_, handler, message) => {
      createComponent({ propsData: { selectedAssignees: [mockUser] }, mutationHandler: handler });
      await openDropdown();

      findDropdown().vm.$emit('select', 'bob');
      await closeDropdown();

      expect(createAlert).toHaveBeenCalledWith({ message });
      expect(findDropdown().props('selected')).toBe('root');
    });
  });

  describe('with a user that cannot be assigned', () => {
    it('disables them so they cannot be selected', async () => {
      createComponent({ users: [mockOtherUser, mockDisabledUser] });
      await openDropdown();

      expect(options(0)).toMatchObject([
        { value: 'root', disabled: false },
        { value: 'bob', disabled: false },
        { value: 'agent', disabled: true },
      ]);
    });

    it('keeps them selectable once assigned, so they can be unassigned', async () => {
      createComponent({
        propsData: { selectedAssignees: [mockDisabledUser] },
        users: [mockDisabledUser, mockOtherUser],
      });
      await openDropdown();

      expect(options(0)).toMatchObject([{ value: 'agent', disabled: false }]);
    });
  });
});
