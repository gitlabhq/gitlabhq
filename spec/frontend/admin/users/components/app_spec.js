import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AdminUsersApp from '~/admin/users/components/app.vue';
import UserActions from '~/admin/users/components/user_actions.vue';
import getUsersMembershipCountsQuery from '~/admin/users/graphql/queries/get_users_membership_counts.query.graphql';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import { createAlert } from '~/alert';
import { users, paths, createMembershipCountResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('AdminUsersApp component', () => {
  let wrapper;
  const user = users[0];

  const mockSuccessData = [{ id: user.id, groupCount: 5, projectCount: 10 }];
  const mockParsedMembershipCount = { 2177: { groupCount: 5, projectCount: 10 } };
  const mockError = new Error();

  const createFetchMembershipCount = (data) =>
    jest.fn().mockResolvedValue(createMembershipCountResponse(data));
  const loadingResolver = jest.fn().mockResolvedValue(new Promise(() => {}));
  const errorResolver = jest.fn().mockRejectedValueOnce(mockError);
  const successfulResolver = createFetchMembershipCount(mockSuccessData);

  function createMockApolloProvider(resolverMock) {
    const requestHandlers = [[getUsersMembershipCountsQuery, resolverMock]];

    return createMockApollo(requestHandlers);
  }

  const initComponent = (props = {}, resolverMock = successfulResolver) => {
    wrapper = mount(AdminUsersApp, {
      apolloProvider: createMockApolloProvider(resolverMock),
      propsData: {
        users,
        paths,
        ...props,
      },
    });
  };

  const findUsersTable = () => wrapper.findComponent(UsersTable);
  const findAllUserActions = () => wrapper.findAllComponents(UserActions);

  describe.each`
    description                                   | mockResolver          | loading  | membershipCounts             | error
    ${'when API call is loading'}                 | ${loadingResolver}    | ${true}  | ${{}}                        | ${false}
    ${'when API returns successful with results'} | ${successfulResolver} | ${false} | ${mockParsedMembershipCount} | ${false}
    ${'when API returns error'}                   | ${errorResolver}      | ${false} | ${{}}                        | ${true}
  `('$description', ({ mockResolver, loading, membershipCounts, error }) => {
    beforeEach(async () => {
      initComponent({}, mockResolver);
      await waitForPromises();
    });

    it(`renders the UsersTable with membership-counts-loading set to ${loading}`, () => {
      expect(findUsersTable().props('membershipCountsLoading')).toBe(loading);
    });

    it('renders the UsersTable with the correct membership-counts data', () => {
      expect(findUsersTable().props('membershipCounts')).toStrictEqual(membershipCounts);
    });

    it(`does ${error ? '' : 'not '}render an error message`, () => {
      return error
        ? expect(createAlert).toHaveBeenCalledWith({
            message: 'Could not load user membership counts. Please refresh the page to try again.',
            error: mockError,
            captureError: true,
          })
        : expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('UserActions', () => {
    beforeEach(async () => {
      initComponent();
      await waitForPromises();
    });

    it('renders a UserActions component for each user', () => {
      expect(findAllUserActions().wrappers.map((w) => w.props('user'))).toStrictEqual(users);
    });
  });
});
