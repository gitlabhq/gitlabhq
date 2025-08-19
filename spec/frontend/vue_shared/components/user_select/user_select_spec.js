import { GlSearchBoxByType } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import searchUsersQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import searchUsersQueryOnMR from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import getIssueParticipantsQuery from '~/sidebar/queries/get_issue_participants.query.graphql';
import UserSelect from '~/vue_shared/components/user_select/user_select.vue';
import {
  projectAutocompleteMembersResponse,
  searchAutocompleteQueryResponse,
  searchAutocompleteResponseOnMR,
  participantsQueryResponse,
  mockUser1,
  mockUser2,
} from 'jest/sidebar/mock_data';

const assignee = {
  id: 'gid://gitlab/User/4',
  avatarUrl:
    'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
  name: 'Developer',
  username: 'dev',
  webUrl: '/dev',
  webPath: '/dev',
  status: null,
};

const mockError = jest.fn().mockRejectedValue('Error!');

const waitForSearch = async () => {
  jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  await nextTick();
  await waitForPromises();
};

const focusInput = jest.fn();

Vue.use(VueApollo);

describe('User select dropdown', () => {
  let wrapper;
  let fakeApollo;
  const hideDropdownMock = jest.fn();

  const findSearchField = () => wrapper.findComponent(GlSearchBoxByType);
  const findParticipantsLoading = () => wrapper.findByTestId('loading-participants');
  const findSelectedParticipants = () => wrapper.findAllByTestId('selected-participant');
  const findSelectedParticipantByIndex = (index) =>
    findSelectedParticipants().at(index).findComponent(SidebarParticipant);
  const findUnselectedParticipants = () => wrapper.findAllByTestId('unselected-participant');
  const findUnselectedParticipantByIndex = (index) =>
    findUnselectedParticipants().at(index).findComponent(SidebarParticipant);
  const findCurrentUser = () => wrapper.findAllByTestId('current-user');
  const findIssuableAuthor = () => wrapper.findAllByTestId('issuable-author');
  const findUnassignLink = () => wrapper.findByTestId('unassign');
  const findEmptySearchResults = () => wrapper.findAllByTestId('empty-results');

  const searchQueryHandlerSuccess = jest.fn().mockResolvedValue(projectAutocompleteMembersResponse);
  const participantsQueryHandlerSuccess = jest.fn().mockResolvedValue(participantsQueryResponse);

  const createComponent = ({
    props = {},
    searchQueryHandler = searchQueryHandlerSuccess,
    participantsQueryHandler = participantsQueryHandlerSuccess,
  } = {}) => {
    fakeApollo = createMockApollo([
      [searchUsersQuery, searchQueryHandler],
      [searchUsersQueryOnMR, jest.fn().mockResolvedValue(searchAutocompleteResponseOnMR)],
      [getIssueParticipantsQuery, participantsQueryHandler],
    ]);
    wrapper = shallowMountExtended(UserSelect, {
      apolloProvider: fakeApollo,
      propsData: {
        headerText: 'test',
        text: 'test-text',
        fullPath: '/project',
        iid: '1',
        value: [],
        currentUser: {
          username: 'random',
          name: 'Mr. Random',
        },
        allowMultipleAssignees: false,
        ...props,
      },
      stubs: {
        GlDropdown: {
          template: `
            <div>
              <slot name="header"></slot>
              <slot></slot>
              <slot name="footer"></slot>
            </div>
          `,
          methods: {
            hide: hideDropdownMock,
          },
        },
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          methods: {
            focusInput,
          },
        }),
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
    hideDropdownMock.mockClear();
  });

  it('renders a loading spinner if participants are loading', () => {
    createComponent();

    expect(findParticipantsLoading().exists()).toBe(true);
  });

  it('skips the queries if `isEditing` prop is false', () => {
    createComponent({ props: { isEditing: false } });

    expect(findParticipantsLoading().exists()).toBe(false);
    expect(searchQueryHandlerSuccess).not.toHaveBeenCalled();
    expect(participantsQueryHandlerSuccess).not.toHaveBeenCalled();
  });

  it('skips the participant query if `iid` is not defined', () => {
    createComponent({ props: { iid: null } });

    expect(participantsQueryHandlerSuccess).not.toHaveBeenCalled();
  });

  it('emits an `error` event if participants query was rejected', async () => {
    createComponent({ participantsQueryHandler: mockError });
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[]]);
  });

  it('emits an `error` event if search query was rejected', async () => {
    createComponent({ searchQueryHandler: mockError });
    await waitForSearch();

    expect(wrapper.emitted('error')).toEqual([[]]);
  });

  it('renders current user if they are not in participants or assignees', async () => {
    createComponent();
    await waitForPromises();

    expect(findCurrentUser().exists()).toBe(true);
  });

  it('does not render current user if user is not logged in', async () => {
    createComponent({
      props: {
        currentUser: {},
      },
    });
    await waitForPromises();

    expect(findCurrentUser().exists()).toBe(false);
  });

  it('does not render issuable author if author is not passed as a prop', async () => {
    createComponent();
    await waitForPromises();

    expect(findIssuableAuthor().exists()).toBe(false);
  });

  describe('when issuable author is passed as a prop', () => {
    it('moves issuable author on top of assigned list, if author is assigned', async () => {
      createComponent({
        props: {
          value: [assignee, mockUser2],
          issuableAuthor: mockUser2,
        },
      });
      await waitForPromises();

      expect(findSelectedParticipantByIndex(0).props('user')).toEqual(mockUser2);
    });

    it('moves issuable author on top of assigned list after current user, if author and current user are assigned', async () => {
      const currentUser = mockUser1;
      const issuableAuthor = mockUser2;

      createComponent({
        props: {
          value: [assignee, issuableAuthor, currentUser],
          issuableAuthor,
          currentUser,
        },
      });
      await waitForPromises();

      expect(findSelectedParticipantByIndex(0).props('user')).toEqual(currentUser);
      expect(findSelectedParticipantByIndex(1).props('user')).toEqual(issuableAuthor);
    });

    it('moves issuable author on top of unassigned list, if author is unassigned project member', async () => {
      createComponent({
        props: {
          issuableAuthor: mockUser2,
        },
      });
      await waitForPromises();
      expect(findUnselectedParticipantByIndex(0).props('user')).toMatchObject(mockUser2);
    });

    it('moves issuable author on top of unassigned list after current user, if author and current user are unassigned project members', async () => {
      const currentUser = mockUser2;
      const issuableAuthor = mockUser1;

      createComponent({
        props: {
          issuableAuthor,
          currentUser,
        },
      });
      await waitForPromises();

      expect(findUnselectedParticipantByIndex(0).props('user')).toEqual(mockUser2);
      expect(findUnselectedParticipantByIndex(1).props('user')).toMatchObject(mockUser1);
    });

    it('displays author in a designated position if author is not assigned and not a project member', async () => {
      createComponent({
        props: {
          issuableAuthor: assignee,
        },
      });
      await waitForPromises();

      expect(findIssuableAuthor().exists()).toBe(true);
    });
  });

  it('displays correct amount of selected users', async () => {
    createComponent({
      props: {
        value: [assignee],
      },
    });
    await waitForPromises();

    expect(findSelectedParticipants()).toHaveLength(1);
  });

  it('does not render a `Cannot merge` tooltip', async () => {
    createComponent();
    await waitForPromises();

    expect(findUnselectedParticipants().at(0).attributes('title')).toBe('');
  });

  describe('when search is empty', () => {
    it('renders a merged list of participants and project members', async () => {
      createComponent();
      await waitForPromises();

      expect(findUnselectedParticipants()).toHaveLength(4);
    });

    it('renders `Unassigned` link with the checkmark when there are no selected users', async () => {
      createComponent();
      await waitForPromises();
      expect(findUnassignLink().props('isChecked')).toBe(true);
    });

    it('renders `Unassigned` link without the checkmark when there are selected users', async () => {
      createComponent({
        props: {
          value: [assignee],
        },
      });
      await waitForPromises();
      expect(findUnassignLink().props('isChecked')).toBe(false);
    });

    it('emits an input event with empty array after clicking on `Unassigned`', async () => {
      createComponent({
        props: {
          value: [assignee],
        },
      });
      await waitForPromises();
      findUnassignLink().trigger('click');

      expect(wrapper.emitted('input')).toEqual([[[]]]);
    });

    it('hides the dropdown after clicking on `Unassigned`', async () => {
      createComponent({
        props: {
          value: [assignee],
        },
      });

      await waitForPromises();

      findUnassignLink().trigger('click');

      expect(hideDropdownMock).toHaveBeenCalledTimes(1);
    });

    it('emits an empty array after unselecting the only selected assignee', async () => {
      createComponent({
        props: {
          value: [assignee],
        },
      });
      await waitForPromises();

      findSelectedParticipants().at(0).trigger('click');
      expect(wrapper.emitted('input')).toEqual([[[]]]);
    });

    it('allows only one user to be selected if `allowMultipleAssignees` is false', async () => {
      createComponent({
        props: {
          value: [assignee],
        },
      });
      await waitForPromises();

      findUnselectedParticipants().at(0).trigger('click');

      expect(wrapper.emitted('input')).toMatchObject([
        [
          [
            {
              avatarUrl:
                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
              id: 'gid://gitlab/User/1',
              name: 'Administrator',
              status: null,
              username: 'root',
              webUrl: '/root',
            },
          ],
        ],
      ]);
    });

    it('adds user to selected if `allowMultipleAssignees` is true', async () => {
      createComponent({
        props: {
          value: [assignee],
          allowMultipleAssignees: true,
        },
      });
      await waitForPromises();

      findUnselectedParticipants().at(0).trigger('click');
      expect(wrapper.emitted('input')[0][0]).toHaveLength(2);
    });
  });

  describe('when searching', () => {
    it('does not show loading spinner when debounce timer is still running', async () => {
      createComponent();
      await waitForPromises();
      findSearchField().vm.$emit('input', 'roo');

      expect(findParticipantsLoading().exists()).toBe(false);
    });

    it('shows loading spinner when searching for users', async () => {
      createComponent();
      await waitForPromises();
      findSearchField().vm.$emit('input', 'roo');
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await nextTick();

      expect(findParticipantsLoading().exists()).toBe(true);
    });

    it('renders a list of found users and external participants matching search term', async () => {
      createComponent({
        searchQueryHandler: jest.fn().mockResolvedValue(searchAutocompleteQueryResponse),
      });
      await waitForPromises();

      findSearchField().vm.$emit('input', 'ro');
      await waitForSearch();

      expect(findUnselectedParticipants()).toHaveLength(3);
    });

    it('renders a list of found users only if no external participants match search term', async () => {
      createComponent({
        searchQueryHandler: jest.fn().mockResolvedValue(searchAutocompleteQueryResponse),
      });
      await waitForPromises();

      findSearchField().vm.$emit('input', 'roo');
      await waitForSearch();

      expect(findUnselectedParticipants()).toHaveLength(2);
    });

    it('shows a message about no matches if search returned an empty list', async () => {
      const responseCopy = cloneDeep(searchAutocompleteQueryResponse);
      responseCopy.data.workspace.users = [];

      createComponent({
        searchQueryHandler: jest.fn().mockResolvedValue(responseCopy),
      });
      await waitForPromises();
      findSearchField().vm.$emit('input', 'tango');
      await waitForSearch();

      expect(findUnselectedParticipants()).toHaveLength(0);
      expect(findEmptySearchResults().exists()).toBe(true);
    });

    it('clears search term and focuses search field after selecting a user', async () => {
      createComponent({
        searchQueryHandler: jest.fn().mockResolvedValue(searchAutocompleteQueryResponse),
      });
      await waitForPromises();

      findSearchField().vm.$emit('input', 'roo');
      await waitForSearch();

      findUnselectedParticipants().at(0).trigger('click');
      await nextTick();

      expect(findSearchField().props('value')).toBe('');
      expect(focusInput).toHaveBeenCalled();
    });

    it('clears search term and focuses search field after unselecting a user', async () => {
      createComponent({
        props: {
          value: [searchAutocompleteQueryResponse.data.workspace.users[0]],
        },
        searchQueryHandler: jest.fn().mockResolvedValue(searchAutocompleteQueryResponse),
      });
      await waitForPromises();

      expect(findSelectedParticipants()).toHaveLength(1);

      findSearchField().vm.$emit('input', 'roo');
      await waitForSearch();

      findSelectedParticipants().at(0).trigger('click');
      await nextTick();

      expect(findSearchField().props('value')).toBe('');
      expect(focusInput).toHaveBeenCalled();
    });
  });

  describe('when on merge request sidebar', () => {
    beforeEach(() => {
      createComponent({ props: { issuableType: TYPE_MERGE_REQUEST, issuableId: 1 } });
      return waitForPromises();
    });

    it('does not render a `Cannot merge` tooltip for a user that has merge permission', () => {
      expect(findUnselectedParticipants().at(0).attributes('title')).toBe('');
    });

    it('renders a `Cannot merge` tooltip for a user that does not have merge permission', () => {
      expect(findUnselectedParticipants().at(1).attributes('title')).toBe('Cannot merge');
    });
  });
});
