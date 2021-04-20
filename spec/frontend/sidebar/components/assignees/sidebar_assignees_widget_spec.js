import { GlSearchBoxByType, GlDropdown } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import searchUsersQuery from '~/graphql_shared/queries/users_search.query.graphql';
import { IssuableType } from '~/issue_show/constants';
import SidebarAssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { ASSIGNEES_DEBOUNCE_DELAY } from '~/sidebar/constants';
import MultiSelectDropdown from '~/vue_shared/components/sidebar/multiselect_dropdown.vue';
import getIssueParticipantsQuery from '~/vue_shared/components/sidebar/queries/get_issue_participants.query.graphql';
import updateIssueAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_issue_assignees.mutation.graphql';
import {
  issuableQueryResponse,
  searchQueryResponse,
  updateIssueAssigneesMutationResponse,
} from '../../mock_data';

jest.mock('~/flash');

const updateIssueAssigneesMutationSuccess = jest
  .fn()
  .mockResolvedValue(updateIssueAssigneesMutationResponse);
const mockError = jest.fn().mockRejectedValue('Error!');

const localVue = createLocalVue();
localVue.use(VueApollo);

const initialAssignees = [
  {
    id: 'some-user',
    avatarUrl: 'some-user-avatar',
    name: 'test',
    username: 'test',
    webUrl: '/test',
  },
];

describe('Sidebar assignees widget', () => {
  let wrapper;
  let fakeApollo;

  const findAssignees = () => wrapper.findComponent(IssuableAssignees);
  const findRealtimeAssignees = () => wrapper.findComponent(SidebarAssigneesRealtime);
  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findDropdown = () => wrapper.findComponent(MultiSelectDropdown);
  const findInviteMembersLink = () => wrapper.findComponent(SidebarInviteMembers);
  const findSearchField = () => wrapper.findComponent(GlSearchBoxByType);

  const findParticipantsLoading = () => wrapper.find('[data-testid="loading-participants"]');
  const findSelectedParticipants = () => wrapper.findAll('[data-testid="selected-participant"]');
  const findUnselectedParticipants = () =>
    wrapper.findAll('[data-testid="unselected-participant"]');
  const findCurrentUser = () => wrapper.findAll('[data-testid="current-user"]');
  const findUnassignLink = () => wrapper.find('[data-testid="unassign"]');
  const findEmptySearchResults = () => wrapper.find('[data-testid="empty-results"]');

  const expandDropdown = () => wrapper.vm.$refs.toggle.expand();

  const createComponent = ({
    search = '',
    issuableQueryHandler = jest.fn().mockResolvedValue(issuableQueryResponse),
    searchQueryHandler = jest.fn().mockResolvedValue(searchQueryResponse),
    updateIssueAssigneesMutationHandler = updateIssueAssigneesMutationSuccess,
    props = {},
    provide = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [getIssueParticipantsQuery, issuableQueryHandler],
      [searchUsersQuery, searchQueryHandler],
      [updateIssueAssigneesMutation, updateIssueAssigneesMutationHandler],
    ]);
    wrapper = shallowMount(SidebarAssigneesWidget, {
      localVue,
      apolloProvider: fakeApollo,
      propsData: {
        iid: '1',
        fullPath: '/mygroup/myProject',
        ...props,
      },
      data() {
        return {
          search,
          selected: [],
        };
      },
      provide: {
        canUpdate: true,
        rootPath: '/',
        ...provide,
      },
      stubs: {
        SidebarEditableItem,
        MultiSelectDropdown,
        GlSearchBoxByType,
        GlDropdown,
      },
    });
  };

  beforeEach(() => {
    gon.current_username = 'root';
    gon.current_user_fullname = 'Administrator';
    gon.current_user_avatar_url = '/root';
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    fakeApollo = null;
    delete gon.current_username;
  });

  describe('with passed initial assignees', () => {
    it('passes `initialLoading` as false to editable item', () => {
      createComponent({
        props: {
          initialAssignees,
        },
      });

      expect(findEditableItem().props('initialLoading')).toBe(false);
    });

    it('renders an initial assignees list with initialAssignees prop', () => {
      createComponent({
        props: {
          initialAssignees,
        },
      });

      expect(findAssignees().props('users')).toEqual(initialAssignees);
    });

    it('renders a collapsible item title calculated with initial assignees length', () => {
      createComponent({
        props: {
          initialAssignees,
        },
      });

      expect(findEditableItem().props('title')).toBe('Assignee');
    });

    describe('when expanded', () => {
      it('renders a loading spinner if participants are loading', () => {
        createComponent({
          props: {
            initialAssignees,
          },
        });
        expandDropdown();

        expect(findParticipantsLoading().exists()).toBe(true);
      });
    });
  });

  describe('without passed initial assignees', () => {
    it('passes `initialLoading` as true to editable item', () => {
      createComponent();

      expect(findEditableItem().props('initialLoading')).toBe(true);
    });

    it('renders assignees list from API response when resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(findAssignees().props('users')).toEqual(
        issuableQueryResponse.data.workspace.issuable.assignees.nodes,
      );
    });

    it('renders an error when issuable query is rejected', async () => {
      createComponent({
        issuableQueryHandler: mockError,
      });
      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
        message: 'An error occurred while fetching participants.',
      });
    });

    it('assigns current user when clicking `Assign self`', async () => {
      createComponent();

      await waitForPromises();

      findAssignees().vm.$emit('assign-self');

      expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
        assigneeUsernames: 'root',
        fullPath: '/mygroup/myProject',
        iid: '1',
      });

      await waitForPromises();

      expect(
        findAssignees()
          .props('users')
          .some((user) => user.username === 'root'),
      ).toBe(true);
    });

    it('emits an event with assignees list on successful mutation', async () => {
      createComponent();

      await waitForPromises();

      findAssignees().vm.$emit('assign-self');

      expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
        assigneeUsernames: 'root',
        fullPath: '/mygroup/myProject',
        iid: '1',
      });

      await waitForPromises();

      expect(wrapper.emitted('assignees-updated')).toEqual([
        [
          [
            {
              __typename: 'User',
              avatarUrl:
                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
              id: 'gid://gitlab/User/1',
              name: 'Administrator',
              username: 'root',
              webUrl: '/root',
              status: null,
            },
          ],
        ],
      ]);
    });

    it('renders current user if they are not in participants or assignees', async () => {
      gon.current_username = 'random';
      gon.current_user_fullname = 'Mr Random';
      gon.current_user_avatar_url = '/random';

      createComponent();
      await waitForPromises();
      expandDropdown();

      expect(findCurrentUser().exists()).toBe(true);
    });

    describe('when expanded', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
        expandDropdown();
      });

      it('collapses the widget on multiselect dropdown toggle event', async () => {
        findDropdown().vm.$emit('toggle');
        await nextTick();
        expect(findDropdown().isVisible()).toBe(false);
      });

      it('renders participants list with correct amount of selected and unselected', async () => {
        expect(findSelectedParticipants()).toHaveLength(1);
        expect(findUnselectedParticipants()).toHaveLength(2);
      });

      it('does not render current user if they are in participants', () => {
        expect(findCurrentUser().exists()).toBe(false);
      });

      it('unassigns all participants when clicking on `Unassign`', () => {
        findUnassignLink().vm.$emit('click');
        findEditableItem().vm.$emit('close');

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: [],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });
    });

    describe('when multiselect is disabled', () => {
      beforeEach(async () => {
        createComponent({ props: { multipleAssignees: false } });
        await waitForPromises();
        expandDropdown();
      });

      it('adds a single assignee when clicking on unselected user', async () => {
        findUnselectedParticipants().at(0).vm.$emit('click');

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: ['root'],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });

      it('removes an assignee when clicking on selected user', () => {
        findSelectedParticipants().at(0).vm.$emit('click', new Event('click'));

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: [],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });
    });

    describe('when multiselect is enabled', () => {
      beforeEach(async () => {
        createComponent({ props: { multipleAssignees: true } });
        await waitForPromises();
        expandDropdown();
      });

      it('adds a few assignees after clicking on unselected users and closing a dropdown', () => {
        findUnselectedParticipants().at(0).vm.$emit('click');
        findUnselectedParticipants().at(1).vm.$emit('click');
        findEditableItem().vm.$emit('close');

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: ['francina.skiles', 'root', 'johndoe'],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });

      it('removes an assignee when clicking on selected user and then closing dropdown', () => {
        findSelectedParticipants().at(0).vm.$emit('click', new Event('click'));

        findEditableItem().vm.$emit('close');

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: [],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });

      it('does not call a mutation when clicking on participants until dropdown is closed', () => {
        findUnselectedParticipants().at(0).vm.$emit('click');
        findSelectedParticipants().at(0).vm.$emit('click', new Event('click'));

        expect(updateIssueAssigneesMutationSuccess).not.toHaveBeenCalled();
      });
    });

    it('shows an error if update assignees mutation is rejected', async () => {
      createComponent({ updateIssueAssigneesMutationHandler: mockError });
      await waitForPromises();
      expandDropdown();

      findUnassignLink().vm.$emit('click');
      findEditableItem().vm.$emit('close');

      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
        message: 'An error occurred while updating assignees.',
      });
    });

    describe('when searching', () => {
      it('does not show loading spinner when debounce timer is still running', async () => {
        createComponent({ search: 'roo' });
        await waitForPromises();
        expandDropdown();

        expect(findParticipantsLoading().exists()).toBe(false);
      });

      it('shows loading spinner when searching for users', async () => {
        createComponent({ search: 'roo' });
        await waitForPromises();
        expandDropdown();
        jest.advanceTimersByTime(ASSIGNEES_DEBOUNCE_DELAY);
        await nextTick();

        expect(findParticipantsLoading().exists()).toBe(true);
      });

      it('renders a list of found users and external participants matching search term', async () => {
        const responseCopy = cloneDeep(issuableQueryResponse);
        responseCopy.data.workspace.issuable.participants.nodes.push({
          id: 'gid://gitlab/User/5',
          avatarUrl: '/someavatar',
          name: 'Roodie',
          username: 'roodie',
          webUrl: '/roodie',
          status: null,
        });

        const issuableQueryHandler = jest.fn().mockResolvedValue(responseCopy);

        createComponent({ issuableQueryHandler });
        await waitForPromises();
        expandDropdown();

        findSearchField().vm.$emit('input', 'roo');
        await nextTick();

        jest.advanceTimersByTime(ASSIGNEES_DEBOUNCE_DELAY);
        await nextTick();
        await waitForPromises();

        expect(findUnselectedParticipants()).toHaveLength(3);
      });

      it('renders a list of found users only if no external participants match search term', async () => {
        createComponent({ search: 'roo' });
        await waitForPromises();
        expandDropdown();
        jest.advanceTimersByTime(250);
        await nextTick();
        await waitForPromises();

        expect(findUnselectedParticipants()).toHaveLength(2);
      });

      it('shows a message about no matches if search returned an empty list', async () => {
        const responseCopy = cloneDeep(searchQueryResponse);
        responseCopy.data.workspace.users.nodes = [];

        createComponent({
          search: 'roo',
          searchQueryHandler: jest.fn().mockResolvedValue(responseCopy),
        });
        await waitForPromises();
        expandDropdown();
        jest.advanceTimersByTime(ASSIGNEES_DEBOUNCE_DELAY);
        await nextTick();
        await waitForPromises();

        expect(findUnselectedParticipants()).toHaveLength(0);
        expect(findEmptySearchResults().exists()).toBe(true);
      });

      it('shows an error if search query was rejected', async () => {
        createComponent({ search: 'roo', searchQueryHandler: mockError });
        await waitForPromises();
        expandDropdown();
        jest.advanceTimersByTime(250);
        await nextTick();
        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({
          message: 'An error occurred while searching users.',
        });
      });
    });
  });

  describe('when user is not signed in', () => {
    beforeEach(() => {
      gon.current_username = undefined;
      createComponent();
    });

    it('does not show current user in the dropdown', () => {
      expandDropdown();
      expect(findCurrentUser().exists()).toBe(false);
    });

    it('passes signedIn prop as false to IssuableAssignees', () => {
      expect(findAssignees().props('signedIn')).toBe(false);
    });
  });

  it('when realtime feature flag is disabled', async () => {
    createComponent();
    await waitForPromises();
    expect(findRealtimeAssignees().exists()).toBe(false);
  });

  it('when realtime feature flag is enabled', async () => {
    createComponent({
      provide: {
        glFeatures: {
          realTimeIssueSidebar: true,
        },
      },
    });
    await waitForPromises();
    expect(findRealtimeAssignees().exists()).toBe(true);
  });

  describe('when making changes to participants list', () => {
    beforeEach(async () => {
      createComponent();
    });

    it('passes falsy `isDirty` prop to editable item if no changes to selected users were made', () => {
      expandDropdown();
      expect(findEditableItem().props('isDirty')).toBe(false);
    });

    it('passes truthy `isDirty` prop if selected users list was changed', async () => {
      expandDropdown();
      expect(findEditableItem().props('isDirty')).toBe(false);
      findUnselectedParticipants().at(0).vm.$emit('click');
      await nextTick();
      expect(findEditableItem().props('isDirty')).toBe(true);
    });

    it('passes falsy `isDirty` prop after dropdown is closed', async () => {
      expandDropdown();
      findUnselectedParticipants().at(0).vm.$emit('click');
      findEditableItem().vm.$emit('close');
      await waitForPromises();
      expect(findEditableItem().props('isDirty')).toBe(false);
    });
  });

  it('does not render invite members link on non-issue sidebar', async () => {
    createComponent({ props: { issuableType: IssuableType.MergeRequest } });
    await waitForPromises();
    expect(findInviteMembersLink().exists()).toBe(false);
  });

  it('does not render invite members link if `directlyInviteMembers` and `indirectlyInviteMembers` were not passed', async () => {
    createComponent();
    await waitForPromises();
    expect(findInviteMembersLink().exists()).toBe(false);
  });

  it('renders invite members link if `directlyInviteMembers` is true', async () => {
    createComponent({
      provide: {
        directlyInviteMembers: true,
      },
    });
    await waitForPromises();
    expect(findInviteMembersLink().exists()).toBe(true);
  });

  it('renders invite members link if `indirectlyInviteMembers` is true', async () => {
    createComponent({
      provide: {
        indirectlyInviteMembers: true,
      },
    });
    await waitForPromises();
    expect(findInviteMembersLink().exists()).toBe(true);
  });
});
