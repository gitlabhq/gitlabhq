import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockClient } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { STATUS_MERGED, STATUS_OPEN } from '~/issues/constants';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  OPERATOR_NOT,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_DRAFT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MERGED_AFTER,
  TOKEN_TYPE_MERGED_BEFORE,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_STATE,
  TOKEN_TYPE_SUBSCRIBED,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import SearchList from '~/merge_request_dashboard/components/search_list.vue';
import getMergeRequestsQuery from '~/merge_request_dashboard/queries/search/get_merge_requests.query.graphql';

Vue.use(VueApollo);

const mockMergeRequest = {
  __typename: 'MergeRequest',
  id: 'gid://gitlab/MergeRequest/1',
  iid: '1',
  title: 'Title',
  titleHtml: 'Title',
  reference: 'group/project!1',
  state: STATUS_OPEN,
  webPath: '/group/project/-/merge_requests/1',
  draft: false,
  createdAt: '2026-01-01',
  updatedAt: '2026-01-01',
  mergedAt: null,
  upvotes: 0,
  downvotes: 0,
  resolvedDiscussionsCount: 0,
  resolvableDiscussionsCount: 0,
  assignees: { nodes: [] },
  reviewers: { nodes: [] },
  author: null,
  labels: { nodes: [] },
  milestone: null,
  headPipeline: null,
  conflicts: false,
  commitCount: 1,
  sourceBranchExists: true,
  targetBranchExists: true,
  targetBranch: 'main',
  targetBranchPath: '/group/project/-/tree/main',
  taskCompletionStatus: { completedCount: 0, count: 0 },
  hidden: false,
  project: { id: 'gid://gitlab/Project/1', repository: { rootRef: 'main' } },
};

const pageInfo = {
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  endCursor: null,
  __typename: 'PageInfo',
};

describe('Merge request dashboard search list', () => {
  let wrapper;
  let mergeRequestsQueryHandler;
  let push;

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findNoFilterEmptyState = () => wrapper.findByTestId('no-filter-empty-state');
  const lastVariables = () =>
    mergeRequestsQueryHandler.mock.calls[mergeRequestsQueryHandler.mock.calls.length - 1][0];
  const assigneeToken = (data) => ({
    type: TOKEN_TYPE_ASSIGNEE,
    value: { data, operator: OPERATOR_IS },
  });
  const filterBy = async (tokens) => {
    findIssuableList().vm.$emit('filter', tokens);
    await waitForPromises();
  };

  function createComponent({ query = {}, isSignedIn = true } = {}) {
    mergeRequestsQueryHandler = jest
      .fn()
      .mockResolvedValue({ data: { mergeRequests: { nodes: [mockMergeRequest], pageInfo } } });
    push = jest.fn();

    const apolloProvider = new VueApollo({
      defaultClient: createMockClient([]),
      clients: {
        searchClient: createMockClient([[getMergeRequestsQuery, mergeRequestsQueryHandler]]),
      },
    });

    wrapper = shallowMountExtended(SearchList, {
      apolloProvider,
      provide: {
        autocompleteAwardEmojisPath: '/emojis',
        autocompleteUsersPath: '/users',
        dashboardLabelsPath: '/dashboard/labels',
        dashboardMilestonesPath: '/dashboard/milestones',
        hasScopedLabelsFeature: false,
        initialSort: '',
        isPublicVisibilityRestricted: false,
        isSignedIn,
      },
      mocks: { $router: { push }, $route: { query, fullPath: '/search' } },
    });
  }

  describe('with a real filter', () => {
    beforeEach(async () => {
      setWindowLocation('?assignee_username[]=root');
      createComponent();
      await waitForPromises();
    });

    it('queries without a namespace, a search term, or a page size above the field cap', () => {
      expect(lastVariables()).toMatchObject({
        assigneeUsernames: 'root',
        state: STATUS_OPEN,
        firstPageSize: 20,
      });
      expect(lastVariables()).not.toHaveProperty('fullPath');
      expect(lastVariables()).not.toHaveProperty('search');
    });

    it('renders the returned merge requests', () => {
      expect(findIssuableList().props('issuables')).toEqual([
        expect.objectContaining({ id: mockMergeRequest.id }),
      ]);
    });

    it('hides the state tabs and shows no counts', () => {
      expect(findIssuableList().props('tabs')).toEqual([]);
      expect(findIssuableList().props('tabCounts')).toBe(null);
    });

    it('puts the state filter first, defaulted to opened', () => {
      expect(findIssuableList().props('initialFilterValue')[0]).toEqual({
        type: TOKEN_TYPE_STATE,
        value: { data: STATUS_OPEN, operator: OPERATOR_IS },
      });
    });

    it('re-queries and pushes when the state changes', async () => {
      await filterBy([
        assigneeToken('root'),
        { type: TOKEN_TYPE_STATE, value: { data: STATUS_MERGED, operator: OPERATOR_IS } },
      ]);

      expect(lastVariables()).toMatchObject({ state: STATUS_MERGED });
      expect(push).toHaveBeenCalledWith({
        query: expect.objectContaining({ state: STATUS_MERGED }),
      });
    });

    it('drops typed free text but keeps querying the real filter', async () => {
      const calls = mergeRequestsQueryHandler.mock.calls.length;

      await filterBy([
        assigneeToken('jane'),
        { type: FILTERED_SEARCH_TERM, value: { data: 'some text' } },
      ]);

      expect(mergeRequestsQueryHandler.mock.calls.length).toBeGreaterThan(calls);
      expect(lastVariables()).toMatchObject({ assigneeUsernames: 'jane' });
      expect(lastVariables()).not.toHaveProperty('search');
    });

    it('clears the results when the last real filter is removed', async () => {
      await filterBy([]);

      expect(findIssuableList().props('issuables')).toEqual([]);
      expect(findNoFilterEmptyState().exists()).toBe(true);
    });

    it('does not push a URL identical to the current one', async () => {
      const query = wrapper.vm.urlParams;
      createComponent({ query });
      await waitForPromises();

      await filterBy([assigneeToken('root')]);

      expect(push).not.toHaveBeenCalled();
    });
  });

  describe.each`
    scenario                  | search
    ${'no filters at all'}    | ${'?'}
    ${'state only'}           | ${'?state=merged'}
    ${'an empty value'}       | ${'?assignee_username='}
    ${'a bare negation'}      | ${'?not[assignee_username]=root'}
    ${'an Any wildcard'}      | ${'?assignee_username[]=Any'}
    ${'a None wildcard'}      | ${'?assignee_username[]=None'}
    ${'draft only'}           | ${'?draft=no'}
    ${'an unsupported param'} | ${'?target_branch=main'}
    ${'a stale text search'}  | ${'?in=title&search=foo'}
  `('with $scenario', ({ search }) => {
    beforeEach(async () => {
      setWindowLocation(search);
      createComponent();
      await waitForPromises();
    });

    it('does not query, and asks for a filter instead', () => {
      expect(mergeRequestsQueryHandler).not.toHaveBeenCalled();
      expect(findNoFilterEmptyState().exists()).toBe(true);
    });
  });

  describe.each`
    scenario         | search
    ${'empty'}       | ${'?state=&assignee_username[]=root'}
    ${'not a state'} | ${'?state=bogus&assignee_username[]=root'}
    ${'repeated'}    | ${'?state=opened&state=merged&assignee_username[]=root'}
  `('when the state param is $scenario', ({ search }) => {
    it('falls back to opened rather than erroring the page', async () => {
      setWindowLocation(search);
      createComponent();
      await waitForPromises();

      expect(lastVariables()).toMatchObject({ state: STATUS_OPEN });
    });
  });

  describe('when the query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
    });

    it('reports a search timeout without sending it to Sentry', async () => {
      setWindowLocation('?assignee_username[]=root');
      createComponent();
      mergeRequestsQueryHandler.mockRejectedValue({ statusCode: 503 });
      await filterBy([assigneeToken('jane')]);

      expect(findIssuableList().props('searchTimeout')).toBe(true);
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('reports any other failure to Sentry', async () => {
      setWindowLocation('?assignee_username[]=root');
      createComponent();
      mergeRequestsQueryHandler.mockRejectedValue(new Error('boom'));
      await filterBy([assigneeToken('jane')]);

      expect(findIssuableList().props('searchTimeout')).toBe(false);
      expect(Sentry.captureException).toHaveBeenCalled();
    });

    it('clears the error once a later search succeeds', async () => {
      setWindowLocation('?assignee_username[]=root');
      createComponent();
      mergeRequestsQueryHandler.mockRejectedValueOnce(new Error('boom'));
      await filterBy([assigneeToken('jane')]);

      expect(findIssuableList().props('error')).toBe(
        'An error occurred while loading merge requests',
      );

      await filterBy([assigneeToken('root')]);

      expect(findIssuableList().props('error')).toBe(null);
    });
  });

  it('keeps a negation alongside a real filter', async () => {
    setWindowLocation('?assignee_username[]=root&not[label_name][]=bug');
    createComponent();
    await waitForPromises();

    expect(lastVariables()).toMatchObject({ assigneeUsernames: 'root' });
    expect([lastVariables().not.labelName].flat()).toContain('bug');
    expect(findIssuableList().props('initialFilterValue')).toEqual(
      expect.arrayContaining([
        { type: TOKEN_TYPE_LABEL, value: { data: 'bug', operator: OPERATOR_NOT } },
      ]),
    );
  });

  describe('filter tokens', () => {
    const tokenTypes = () =>
      findIssuableList()
        .props('searchTokens')
        .map((token) => token.type);

    it('offers every structured token for the opened state', async () => {
      setWindowLocation('?assignee_username[]=root');
      createComponent();
      await waitForPromises();

      expect(tokenTypes()).toEqual([
        TOKEN_TYPE_STATE,
        TOKEN_TYPE_AUTHOR,
        TOKEN_TYPE_ASSIGNEE,
        TOKEN_TYPE_REVIEWER,
        TOKEN_TYPE_APPROVED_BY,
        TOKEN_TYPE_MERGE_USER,
        TOKEN_TYPE_MILESTONE,
        TOKEN_TYPE_LABEL,
        TOKEN_TYPE_MY_REACTION,
        TOKEN_TYPE_DRAFT,
        TOKEN_TYPE_SUBSCRIBED,
      ]);
    });

    it('offers the merged date tokens only for the merged state', async () => {
      setWindowLocation('?assignee_username[]=root&state=merged');
      createComponent();
      await waitForPromises();

      expect(tokenTypes()).toEqual(
        expect.arrayContaining([TOKEN_TYPE_MERGED_BEFORE, TOKEN_TYPE_MERGED_AFTER]),
      );
    });

    it('drops the tokens that need a signed-in user', async () => {
      setWindowLocation('?assignee_username[]=root');
      createComponent({ isSignedIn: false });
      await waitForPromises();

      expect(tokenTypes()).not.toContain(TOKEN_TYPE_MY_REACTION);
      expect(tokenTypes()).not.toContain(TOKEN_TYPE_SUBSCRIBED);
    });

    it('maps the new tokens onto query variables', async () => {
      setWindowLocation('?author_username=jane&label_name[]=bug&milestone_title=16.0');
      createComponent();
      await waitForPromises();

      expect(lastVariables()).toMatchObject({
        authorUsername: 'jane',
        labelName: 'bug',
        milestoneTitle: '16.0',
      });
    });
  });
});
