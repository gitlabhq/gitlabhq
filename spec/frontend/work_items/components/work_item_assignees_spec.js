import { GlLink, GlTokenSelector, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stripTypenames } from 'helpers/graphql_helpers';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import { i18n } from '~/work_items/constants';
import { temporaryConfig, resolvers } from '~/work_items/graphql/provider';
import {
  projectMembersResponseWithCurrentUser,
  mockAssignees,
  workItemQueryResponse,
  currentUserResponse,
  currentUserNullResponse,
  projectMembersResponseWithoutCurrentUser,
} from '../mock_data';

Vue.use(VueApollo);

const workItemId = 'gid://gitlab/WorkItem/1';
const dropdownItems = projectMembersResponseWithCurrentUser.data.workspace.users.nodes;

describe('WorkItemAssignees component', () => {
  let wrapper;

  const findAssigneeLinks = () => wrapper.findAllComponents(GlLink);
  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findAssignSelfButton = () => wrapper.findByTestId('assign-self');
  const findAssigneesTitle = () => wrapper.findByTestId('assignees-title');

  const successSearchQueryHandler = jest
    .fn()
    .mockResolvedValue(projectMembersResponseWithCurrentUser);
  const successCurrentUserQueryHandler = jest.fn().mockResolvedValue(currentUserResponse);
  const noCurrentUserQueryHandler = jest.fn().mockResolvedValue(currentUserNullResponse);

  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const createComponent = ({
    assignees = mockAssignees,
    searchQueryHandler = successSearchQueryHandler,
    currentUserQueryHandler = successCurrentUserQueryHandler,
    allowsMultipleAssignees = true,
  } = {}) => {
    const apolloProvider = createMockApollo(
      [
        [userSearchQuery, searchQueryHandler],
        [currentUserQuery, currentUserQueryHandler],
      ],
      resolvers,
      {
        typePolicies: temporaryConfig.cacheConfig.typePolicies,
      },
    );

    apolloProvider.clients.defaultClient.writeQuery({
      query: workItemQuery,
      variables: {
        id: workItemId,
      },
      data: workItemQueryResponse.data,
    });

    wrapper = mountExtended(WorkItemAssignees, {
      provide: {
        fullPath: 'test-project-path',
      },
      propsData: {
        assignees,
        workItemId,
        allowsMultipleAssignees,
      },
      attachTo: document.body,
      apolloProvider,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('passes the correct data-user-id attribute', () => {
    createComponent();

    expect(findAssigneeLinks().at(0).attributes('data-user-id')).toBe('1');
  });

  it('container does not have shadow by default', () => {
    createComponent();
    expect(findTokenSelector().props('containerClass')).toBe('gl-shadow-none!');
  });

  it('container has shadow after focusing token selector', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findTokenSelector().props('containerClass')).toBe('');
  });

  it('focuses token selector on token selector input event', async () => {
    createComponent();
    findTokenSelector().vm.$emit('input', [mockAssignees[0]]);
    await nextTick();

    expect(findEmptyState().exists()).toBe(false);
    expect(findTokenSelector().element.contains(document.activeElement)).toBe(true);
  });

  it('calls a mutation on clicking outside the token selector', async () => {
    createComponent();
    findTokenSelector().vm.$emit('input', [mockAssignees[0]]);
    findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));
    await waitForPromises();

    expect(findTokenSelector().props('selectedTokens')).toEqual([mockAssignees[0]]);
  });

  describe('when searching for users', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not start user search by default', () => {
      expect(findTokenSelector().props('loading')).toBe(false);
      expect(findTokenSelector().props('dropdownItems')).toEqual([]);
    });

    it('starts user search on hovering for more than 250ms', async () => {
      findTokenSelector().trigger('mouseover');
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await nextTick();

      expect(findTokenSelector().props('loading')).toBe(true);
    });

    it('starts user search on focusing token selector', async () => {
      findTokenSelector().vm.$emit('focus');
      await nextTick();

      expect(findTokenSelector().props('loading')).toBe(true);
    });

    it('does not start searching if token-selector was hovered for less than 250ms', async () => {
      findTokenSelector().trigger('mouseover');
      jest.advanceTimersByTime(100);
      await nextTick();

      expect(findTokenSelector().props('loading')).toBe(false);
    });

    it('does not start searching if cursor was moved out from token selector before 250ms passed', async () => {
      findTokenSelector().trigger('mouseover');
      jest.advanceTimersByTime(100);

      findTokenSelector().trigger('mouseout');
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await nextTick();

      expect(findTokenSelector().props('loading')).toBe(false);
    });

    it('shows skeleton loader on dropdown when loading users', async () => {
      findTokenSelector().vm.$emit('focus');
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('shows correct users list in dropdown when loaded', async () => {
      findTokenSelector().vm.$emit('focus');
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);

      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findTokenSelector().props('dropdownItems')).toHaveLength(2);
    });

    it('should search for users with correct key after text input', async () => {
      const searchKey = 'Hello';

      findTokenSelector().vm.$emit('focus');
      findTokenSelector().vm.$emit('text-input', searchKey);
      await waitForPromises();

      expect(successSearchQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({ search: searchKey }),
      );
    });
  });

  it('emits error event if search users query fails', async () => {
    createComponent({ searchQueryHandler: errorHandler });
    findTokenSelector().vm.$emit('focus');
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[i18n.fetchError]]);
  });

  describe('when assigning to current user', () => {
    it('does not show `Assign myself` button if current user is loading', () => {
      createComponent();
      findTokenSelector().trigger('mouseover');

      expect(findAssignSelfButton().exists()).toBe(false);
    });

    it('does not show `Assign myself` button if work item has assignees', async () => {
      createComponent();
      await waitForPromises();
      findTokenSelector().trigger('mouseover');

      expect(findAssignSelfButton().exists()).toBe(false);
    });

    it('does now show `Assign myself` button if user is not logged in', async () => {
      createComponent({ currentUserQueryHandler: noCurrentUserQueryHandler, assignees: [] });
      await waitForPromises();
      findTokenSelector().trigger('mouseover');

      expect(findAssignSelfButton().exists()).toBe(false);
    });
  });

  describe('when user is logged in and there are no assignees', () => {
    beforeEach(() => {
      createComponent({ assignees: [] });
      return waitForPromises();
    });

    it('renders `Assign myself` button', async () => {
      findTokenSelector().trigger('mouseover');
      expect(findAssignSelfButton().exists()).toBe(true);
    });

    it('calls update work item assignees mutation with current user as a variable on button click', () => {
      // TODO: replace this test as soon as we have a real mutation implemented
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockImplementation(jest.fn());

      findTokenSelector().trigger('mouseover');
      findAssignSelfButton().vm.$emit('click', new MouseEvent('click'));

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              assignees: [stripTypenames(currentUserResponse.data.currentUser)],
              id: workItemId,
            },
          },
        }),
      );
    });
  });

  it('moves current user to the top of dropdown items if user is a project member', async () => {
    createComponent();
    await waitForPromises();

    expect(findTokenSelector().props('dropdownItems')[0]).toEqual(
      expect.objectContaining({
        ...stripTypenames(currentUserResponse.data.currentUser),
      }),
    );
  });

  describe('when current user is not in the list of project members', () => {
    const searchQueryHandler = jest
      .fn()
      .mockResolvedValue(projectMembersResponseWithoutCurrentUser);

    beforeEach(() => {
      createComponent({ searchQueryHandler });
      return waitForPromises();
    });

    it('adds current user to the top of dropdown items', () => {
      expect(findTokenSelector().props('dropdownItems')[0]).toEqual(
        stripTypenames(currentUserResponse.data.currentUser),
      );
    });

    it('does not add current user if search is not empty', async () => {
      findTokenSelector().vm.$emit('text-input', 'test');
      await waitForPromises();

      expect(findTokenSelector().props('dropdownItems')[0]).not.toEqual(
        stripTypenames(currentUserResponse.data.currentUser),
      );
    });
  });

  it('has `Assignee` label when only one assignee is present', () => {
    createComponent({ assignees: [mockAssignees[0]] });

    expect(findAssigneesTitle().text()).toBe('Assignee');
  });

  it('has `Assignees` label if more than one assignee is present', () => {
    createComponent();

    expect(findAssigneesTitle().text()).toBe('Assignees');
  });

  describe('when multiple assignees are allowed', () => {
    beforeEach(() => {
      createComponent({ allowsMultipleAssignees: true, assignees: [] });
      return waitForPromises();
    });

    it('has `Add assignees` text on placeholder', () => {
      expect(findEmptyState().text()).toContain('Add assignees');
    });

    it('adds multiple assignees when token-selector provides multiple values', async () => {
      findTokenSelector().vm.$emit('input', dropdownItems);
      await nextTick();

      expect(findTokenSelector().props('selectedTokens')).toHaveLength(2);
    });
  });

  describe('when multiple assignees are not allowed', () => {
    beforeEach(() => {
      createComponent({ allowsMultipleAssignees: false, assignees: [] });
      return waitForPromises();
    });

    it('has `Add assignee` text on placeholder', () => {
      expect(findEmptyState().text()).toContain('Add assignee');
      expect(findEmptyState().text()).not.toContain('Add assignees');
    });

    it('adds a single assignee token-selector provides multiple values', async () => {
      findTokenSelector().vm.$emit('input', dropdownItems);
      await nextTick();

      expect(findTokenSelector().props('selectedTokens')).toHaveLength(1);
    });

    it('removes shadow after token-selector input', async () => {
      findTokenSelector().vm.$emit('input', dropdownItems);
      await nextTick();

      expect(findTokenSelector().props('containerClass')).toBe('gl-shadow-none!');
    });
  });
});
