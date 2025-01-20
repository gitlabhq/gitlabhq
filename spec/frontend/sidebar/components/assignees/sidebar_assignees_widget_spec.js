import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import SidebarAssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarInviteMembers from '~/sidebar/components/assignees/sidebar_invite_members.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import getIssueAssigneesQuery from '~/sidebar/queries/get_issue_assignees.query.graphql';
import getMrAssigneesQuery from '~/sidebar/queries/get_mr_assignees.query.graphql';
import updateIssueAssigneesMutation from '~/sidebar/queries/update_issue_assignees.mutation.graphql';
import UserSelect from '~/vue_shared/components/user_select/user_select.vue';
import {
  issuableQueryResponse,
  updateIssueAssigneesMutationResponse,
  issuableQueryWithPlaceholderResponse,
  mrAssigneesQueryResponse,
  initialAssigneesPlaceholder,
  initialAssignees,
} from '../../mock_data';

jest.mock('~/alert');

const updateIssueAssigneesMutationSuccess = jest
  .fn()
  .mockResolvedValue(updateIssueAssigneesMutationResponse);
const mockError = jest.fn().mockRejectedValue('Error!');

Vue.use(VueApollo);

describe('Sidebar assignees widget', () => {
  let wrapper;
  let fakeApollo;

  const findAssignees = () => wrapper.findComponent(IssuableAssignees);
  const findRealtimeAssignees = () => wrapper.findComponent(SidebarAssigneesRealtime);
  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findInviteMembersLink = () => wrapper.findComponent(SidebarInviteMembers);
  const findUserSelect = () => wrapper.findComponent(UserSelect);

  const expandDropdown = () => wrapper.vm.$refs.toggle.expand();

  const createComponent = ({
    issuableQueryHandler = jest.fn().mockResolvedValue(issuableQueryResponse),
    updateIssueAssigneesMutationHandler = updateIssueAssigneesMutationSuccess,
    mrQueryHandler = jest.fn().mockResolvedValue(mrAssigneesQueryResponse),
    props = {},
    provide = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [getIssueAssigneesQuery, issuableQueryHandler],
      [updateIssueAssigneesMutation, updateIssueAssigneesMutationHandler],
      [getMrAssigneesQuery, mrQueryHandler],
    ]);
    wrapper = shallowMount(SidebarAssigneesWidget, {
      apolloProvider: fakeApollo,
      propsData: {
        iid: '1',
        issuableId: 0,
        fullPath: '/mygroup/myProject',
        allowMultipleAssignees: true,
        editable: true,
        ...props,
      },
      provide: {
        canUpdate: true,
        rootPath: '/',
        ...provide,
      },
      stubs: {
        SidebarEditableItem,
        UserSelect,
        GlSearchBoxByType,
        GlDropdown: {
          template: `
            <div>
              <slot name="footer"></slot>
            </div>
          `,
          methods: {
            show: jest.fn(),
          },
        },
      },
    });
  };

  beforeEach(() => {
    gon.current_username = 'root';
    gon.current_user_fullname = 'Administrator';
    gon.current_user_avatar_url = '/root';
  });

  afterEach(() => {
    fakeApollo = null;
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
  });

  describe('without passed initial assignees', () => {
    it('passes `initialLoading` as true to editable item', () => {
      createComponent();

      expect(findEditableItem().props('initialLoading')).toBe(true);
    });

    it('renders assignees list from API response when resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(findAssignees().props('users')).toEqual([
        {
          __typename: 'UserCore',
          id: 'gid://gitlab/User/2',
          avatarUrl:
            'https://www.gravatar.com/avatar/a95e5b71488f4b9d69ce5ff58bfd28d6?s=80\u0026d=identicon',
          name: 'Jacki Kub',
          username: 'francina.skiles',
          type: 'HUMAN',
          webUrl: '/franc',
          webPath: '/franc',
          status: null,
        },
      ]);
    });

    it('renders an error when issuable query is rejected', async () => {
      createComponent({
        issuableQueryHandler: mockError,
      });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching participants.',
      });
    });

    it('assigns current user when clicking `Assign self`', async () => {
      createComponent();

      await waitForPromises();

      findAssignees().vm.$emit('assign-self');

      expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
        assigneeUsernames: ['root'],
        fullPath: '/mygroup/myProject',
        iid: '1',
      });

      await waitForPromises();
      await nextTick();

      expect(
        findAssignees()
          .props('users')
          .some((user) => user.username === 'root'),
      ).toBe(true);
    });

    it('emits an event with assignees list and issuable id on successful mutation', async () => {
      createComponent();

      await waitForPromises();

      findAssignees().vm.$emit('assign-self');

      expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
        assigneeUsernames: ['root'],
        fullPath: '/mygroup/myProject',
        iid: '1',
      });

      await waitForPromises();

      expect(wrapper.emitted('assignees-updated')).toEqual([
        [
          {
            assignees: [
              {
                __typename: 'UserCore',
                avatarUrl:
                  'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
                id: 'gid://gitlab/User/1',
                name: 'Administrator',
                username: 'root',
                webUrl: '/root',
                webPath: '/root',
                status: null,
                type: 'HUMAN',
              },
            ],
            id: 'gid://gitlab/Issue/1',
          },
        ],
      ]);
    });

    it('does not trigger mutation or fire event  when editing and exiting without making changes', async () => {
      createComponent();

      await waitForPromises();

      findEditableItem().vm.$emit('open');

      await waitForPromises();

      findEditableItem().vm.$emit('close');

      expect(findEditableItem().props('isDirty')).toBe(false);
      expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledTimes(0);
      expect(wrapper.emitted('assignees-updated')).toBe(undefined);
    });

    describe('when expanded', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
        expandDropdown();
      });

      it('collapses the widget on user select toggle event', async () => {
        findUserSelect().vm.$emit('toggle');
        await nextTick();
        expect(findUserSelect().isVisible()).toBe(false);
      });

      it('calls an update mutation with correct variables on User Select input event', () => {
        findUserSelect().vm.$emit('input', [{ username: 'root' }]);
        findEditableItem().vm.$emit('close');

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: ['root'],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });
    });

    describe('when multiselect is disabled', () => {
      beforeEach(async () => {
        createComponent({ props: { allowMultipleAssignees: false } });
        await waitForPromises();
        expandDropdown();
      });

      it('closes a dropdown after User Select input event', async () => {
        findUserSelect().vm.$emit('input', [{ username: 'root' }]);

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: ['root'],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });

        await waitForPromises();

        expect(findUserSelect().isVisible()).toBe(false);
      });
    });

    describe('when multiselect is enabled', () => {
      beforeEach(async () => {
        createComponent({ props: { allowMultipleAssignees: true } });
        await waitForPromises();
        expandDropdown();
      });

      it('does not call a mutation when clicking on participants until dropdown is closed', () => {
        findUserSelect().vm.$emit('input', [{ username: 'root' }]);

        expect(updateIssueAssigneesMutationSuccess).not.toHaveBeenCalled();
        expect(findUserSelect().isVisible()).toBe(true);
      });

      it('calls the mutation old issuable id if `iid` prop was changed', async () => {
        findUserSelect().vm.$emit('input', [{ username: 'francina.skiles' }]);
        wrapper.setProps({
          iid: '2',
        });
        await nextTick();
        findEditableItem().vm.$emit('close');

        expect(updateIssueAssigneesMutationSuccess).toHaveBeenCalledWith({
          assigneeUsernames: ['francina.skiles'],
          fullPath: '/mygroup/myProject',
          iid: '1',
        });
      });
    });

    it('shows an error if update assignees mutation is rejected', async () => {
      createComponent({ updateIssueAssigneesMutationHandler: mockError });
      await waitForPromises();
      expandDropdown();

      findUserSelect().vm.$emit('input', []);
      findEditableItem().vm.$emit('close');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while updating assignees.',
      });
    });
  });

  describe('when user is not signed in', () => {
    beforeEach(async () => {
      gon.current_username = undefined;
      createComponent();
      await waitForPromises();
    });

    it('passes signedIn prop as false to IssuableAssignees', () => {
      expect(findAssignees().props('signedIn')).toBe(false);
    });
  });

  describe('when issuable is not editable by the user', () => {
    beforeEach(async () => {
      createComponent({ props: { editable: false } });
      await waitForPromises();
    });

    it('passes editable prop as false to IssuableAssignees', () => {
      expect(findAssignees().props('editable')).toBe(false);
    });
  });

  it('includes the real-time assignees component', async () => {
    createComponent();
    await waitForPromises();
    expect(findRealtimeAssignees().exists()).toBe(true);
  });

  describe('when making changes to participants list', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('passes falsy `isDirty` prop to editable item if no changes to selected users were made', () => {
      expandDropdown();
      expect(findEditableItem().props('isDirty')).toBe(false);
    });

    it('passes truthy `isDirty` prop after User Select component emitted an input event', async () => {
      expandDropdown();
      expect(findEditableItem().props('isDirty')).toBe(false);
      findUserSelect().vm.$emit('input', []);
      await nextTick();
      expect(findEditableItem().props('isDirty')).toBe(true);
    });

    it('passes falsy `isDirty` prop after dropdown is closed', async () => {
      expandDropdown();
      findUserSelect().vm.$emit('input', []);
      findEditableItem().vm.$emit('close');
      await waitForPromises();
      expect(findEditableItem().props('isDirty')).toBe(false);
    });
  });

  it('does not render invite members link on non-issue sidebar', async () => {
    createComponent({
      props: { issuableType: TYPE_MERGE_REQUEST },
    });

    await waitForPromises();
    expect(findInviteMembersLink().exists()).toBe(false);
  });

  it('does not render invite members link if `directlyInviteMembers` was not passed', async () => {
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

  describe('when Placeholder users are present', () => {
    const customIssuableQueryHandler = jest
      .fn()
      .mockResolvedValue(issuableQueryWithPlaceholderResponse);

    it('filters out placeholders from the assignees list', async () => {
      createComponent({
        issuableQueryHandler: customIssuableQueryHandler,
      });

      await waitForPromises();

      const assignees = findAssignees().props('users');

      expect(assignees.some((user) => user.type === 'PLACEHOLDER')).toBe(false);
    });

    it('does not display initialAssignee if the initial assignee is a placeholder user', async () => {
      const pendingPromise = new Promise(() => {});
      const loadingQueryHandler = jest.fn().mockReturnValue(pendingPromise);

      createComponent({
        issuableQueryHandler: loadingQueryHandler,
        props: {
          initialAssignees: initialAssigneesPlaceholder,
        },
      });

      await nextTick();

      expect(findEditableItem().props('initialLoading')).toBe(true);
      expect(findAssignees().exists()).toBe(false);
    });

    it('displays the initial assignee if assignee is not a placeholder user', async () => {
      createComponent({
        props: {
          initialAssignees,
        },
      });

      await nextTick();

      const assignees = findAssignees().props('users');
      expect(assignees).toHaveLength(1);
      expect(assignees[0].type).toEqual('HUMAN');
    });

    it('does not show the assignee as selected if the assignee is a placeholder', async () => {
      createComponent({
        issuableQueryHandler: customIssuableQueryHandler,
      });

      await waitForPromises();

      const assignees = findAssignees().props('users');
      expect(assignees).toHaveLength(0);
    });

    it('does not pass placeholder users to user-select as dropdown values', async () => {
      createComponent({
        issuableQueryHandler: customIssuableQueryHandler,
        props: {
          initialAssignees: initialAssigneesPlaceholder,
        },
      });

      await waitForPromises();
      expect(findUserSelect().props('value')).toEqual([]);
    });

    it('does not pass the author to user-select if issuableAuthor is a placeholder user', async () => {
      createComponent({
        issuableQueryHandler: customIssuableQueryHandler,
        props: {
          initialAssignees,
        },
      });

      await waitForPromises();
      expect(findUserSelect().props('issuableAuthor')).toEqual({});
    });
  });
});
