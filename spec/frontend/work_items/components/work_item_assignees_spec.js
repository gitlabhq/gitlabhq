import { GlLink, GlTokenSelector, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import { i18n } from '~/work_items/constants';
import { temporaryConfig, resolvers } from '~/work_items/graphql/provider';
import { projectMembersResponse, mockAssignees, workItemQueryResponse } from '../mock_data';

Vue.use(VueApollo);

const workItemId = 'gid://gitlab/WorkItem/1';

describe('WorkItemAssignees component', () => {
  let wrapper;

  const findAssigneeLinks = () => wrapper.findAllComponents(GlLink);
  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const findEmptyState = () => wrapper.findByTestId('empty-state');

  const successSearchQueryHandler = jest.fn().mockResolvedValue(projectMembersResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const createComponent = ({
    assignees = mockAssignees,
    searchQueryHandler = successSearchQueryHandler,
  } = {}) => {
    const apolloProvider = createMockApollo([[userSearchQuery, searchQueryHandler]], resolvers, {
      typePolicies: temporaryConfig.cacheConfig.typePolicies,
    });

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

  it('does not start user search by default', () => {
    createComponent();

    expect(findTokenSelector().props('loading')).toBe(false);
    expect(findTokenSelector().props('dropdownItems')).toEqual([]);
  });

  it('starts user search on hovering for more than 250ms', async () => {
    createComponent();
    findTokenSelector().trigger('mouseover');
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(true);
  });

  it('starts user search on focusing token selector', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(true);
  });

  it('does not start searching if token-selector was hovered for less than 250ms', async () => {
    createComponent();
    findTokenSelector().trigger('mouseover');
    jest.advanceTimersByTime(100);
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(false);
  });

  it('does not start searching if cursor was moved out from token selector before 250ms passed', async () => {
    createComponent();
    findTokenSelector().trigger('mouseover');
    jest.advanceTimersByTime(100);

    findTokenSelector().trigger('mouseout');
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(false);
  });

  it('shows skeleton loader on dropdown when loading users', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('shows correct user list in dropdown when loaded', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findSkeletonLoader().exists()).toBe(true);

    await waitForPromises();

    expect(findSkeletonLoader().exists()).toBe(false);
    expect(findTokenSelector().props('dropdownItems')).toHaveLength(2);
  });

  it('emits error event if search users query fails', async () => {
    createComponent({ searchQueryHandler: errorHandler });
    findTokenSelector().vm.$emit('focus');
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[i18n.fetchError]]);
  });

  it('should search for users with correct key after text input', async () => {
    const searchKey = 'Hello';

    createComponent();
    findTokenSelector().vm.$emit('focus');
    findTokenSelector().vm.$emit('text-input', searchKey);
    await waitForPromises();

    expect(successSearchQueryHandler).toHaveBeenCalledWith(
      expect.objectContaining({ search: searchKey }),
    );
  });
});
