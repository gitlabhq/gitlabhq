import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import organizationUsersQuery from '~/organizations/users/graphql/organization_users.query.graphql';
import OrganizationsUsersApp from '~/organizations/users/components/app.vue';
import { MOCK_ORGANIZATION_GID, MOCK_USERS } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const mockError = new Error();

const loadingResolver = jest.fn().mockReturnValue(new Promise(() => {}));
const successfulResolver = (nodes) =>
  jest.fn().mockResolvedValue({
    data: { organization: { id: 1, organizationUsers: { nodes } } },
  });
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

  const findOrganizationUsersLoading = () => wrapper.findByText('Loading');
  const findOrganizationUsers = () => wrapper.findByTestId('organization-users');

  describe.each`
    description                                      | mockResolver                      | loading  | userData      | error
    ${'when API call is loading'}                    | ${loadingResolver}                | ${true}  | ${[]}         | ${false}
    ${'when API returns successful with results'}    | ${successfulResolver(MOCK_USERS)} | ${false} | ${MOCK_USERS} | ${false}
    ${'when API returns successful without results'} | ${successfulResolver([])}         | ${false} | ${[]}         | ${false}
    ${'when API returns error'}                      | ${errorResolver}                  | ${false} | ${[]}         | ${true}
  `('$description', ({ mockResolver, loading, userData, error }) => {
    beforeEach(async () => {
      createComponent(mockResolver);
      await waitForPromises();
    });

    it(`does ${
      loading ? '' : 'not '
    }render the organization users view with loading placeholder`, () => {
      expect(findOrganizationUsersLoading().exists()).toBe(loading);
    });

    it(`renders the organization users view with ${
      userData.length ? 'correct' : 'empty'
    } users array raw data`, () => {
      expect(JSON.parse(findOrganizationUsers().text())).toStrictEqual(userData);
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
});
