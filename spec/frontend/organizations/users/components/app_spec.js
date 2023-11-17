import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { ORGANIZATION_USERS_PER_PAGE } from '~/organizations/constants';
import organizationUsersQuery from '~/organizations/users/graphql/organization_users.query.graphql';
import OrganizationsUsersApp from '~/organizations/users/components/app.vue';
import OrganizationsUsersView from '~/organizations/users/components/users_view.vue';
import {
  MOCK_ORGANIZATION_GID,
  MOCK_USERS,
  MOCK_USERS_FORMATTED,
  MOCK_PAGE_INFO,
} from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const mockError = new Error();

const loadingResolver = jest.fn().mockReturnValue(new Promise(() => {}));
const successfulResolver = (nodes, pageInfo = {}) => {
  return jest.fn().mockResolvedValue({
    data: { organization: { id: 1, organizationUsers: { nodes, pageInfo } } },
  });
};
const errorResolver = jest.fn().mockRejectedValueOnce(mockError);

describe('OrganizationsUsersApp', () => {
  let wrapper;
  let mockApollo;

  const createComponent = (mockResolvers = successfulResolver(MOCK_USERS)) => {
    mockApollo = createMockApollo([[organizationUsersQuery, mockResolvers]]);

    wrapper = shallowMountExtended(OrganizationsUsersApp, {
      apolloProvider: mockApollo,
      provide: {
        organizationGid: MOCK_ORGANIZATION_GID,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  const findOrganizationUsersView = () => wrapper.findComponent(OrganizationsUsersView);

  describe.each`
    description                                                     | mockResolver                                      | loading  | userData                | pageInfo          | error
    ${'when API call is loading'}                                   | ${loadingResolver}                                | ${true}  | ${[]}                   | ${{}}             | ${false}
    ${'when API returns successful with one page of results'}       | ${successfulResolver(MOCK_USERS)}                 | ${false} | ${MOCK_USERS_FORMATTED} | ${{}}             | ${false}
    ${'when API returns successful with multiple pages of results'} | ${successfulResolver(MOCK_USERS, MOCK_PAGE_INFO)} | ${false} | ${MOCK_USERS_FORMATTED} | ${MOCK_PAGE_INFO} | ${false}
    ${'when API returns successful without results'}                | ${successfulResolver([])}                         | ${false} | ${[]}                   | ${{}}             | ${false}
    ${'when API returns error'}                                     | ${errorResolver}                                  | ${false} | ${[]}                   | ${{}}             | ${true}
  `('$description', ({ mockResolver, loading, userData, pageInfo, error }) => {
    beforeEach(async () => {
      createComponent(mockResolver);
      await waitForPromises();
    });

    it(`renders OrganizationUsersView with loading prop set to ${loading}`, () => {
      expect(findOrganizationUsersView().props('loading')).toBe(loading);
    });

    it('renders OrganizationUsersView with correct users prop', () => {
      expect(findOrganizationUsersView().props('users')).toStrictEqual(userData);
    });

    it('renders OrganizationUsersView with correct pageInfo prop', () => {
      expect(findOrganizationUsersView().props('pageInfo')).toStrictEqual(pageInfo);
    });

    it(`does ${error ? '' : 'not '}render an error message`, () => {
      return error
        ? expect(createAlert).toHaveBeenCalledWith({
            message:
              'An error occurred loading the organization users. Please refresh the page to try again.',
            error: mockError,
            captureError: true,
          })
        : expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('Pagination', () => {
    const mockResolver = successfulResolver(MOCK_USERS, MOCK_PAGE_INFO);

    beforeEach(async () => {
      createComponent(mockResolver);
      await waitForPromises();
      mockResolver.mockClear();
    });

    it('handleNextPage calls organizationUsersQuery with correct pagination data', async () => {
      findOrganizationUsersView().vm.$emit('next');
      await waitForPromises();

      expect(mockResolver).toHaveBeenCalledWith({
        id: MOCK_ORGANIZATION_GID,
        before: '',
        after: MOCK_PAGE_INFO.endCursor,
        first: ORGANIZATION_USERS_PER_PAGE,
        last: null,
      });
    });

    it('handlePrevPage calls organizationUsersQuery with correct pagination data', async () => {
      findOrganizationUsersView().vm.$emit('prev');
      await waitForPromises();

      expect(mockResolver).toHaveBeenCalledWith({
        id: MOCK_ORGANIZATION_GID,
        before: MOCK_PAGE_INFO.startCursor,
        after: '',
        first: ORGANIZATION_USERS_PER_PAGE,
        last: null,
      });
    });
  });
});
