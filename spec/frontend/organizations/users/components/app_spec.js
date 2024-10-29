import Vue from 'vue';
import VueApollo from 'vue-apollo';
import organizationUsersResponse from 'test_fixtures/graphql/organizations/organization_users.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import organizationUsersQuery from '~/organizations/users/graphql/queries/organization_users.query.graphql';
import OrganizationsUsersApp from '~/organizations/users/components/app.vue';
import OrganizationsUsersView from '~/organizations/users/components/users_view.vue';
import { ORGANIZATION_USERS_PER_PAGE } from '~/organizations/users/constants';
import { pageInfoMultiplePages, pageInfoEmpty } from 'jest/organizations/mock_data';
import { MOCK_USERS_FORMATTED } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const {
  data: {
    organization: {
      id: organizationGid,
      organizationUsers: { nodes, pageInfo },
    },
  },
} = organizationUsersResponse;

const mockError = new Error();

const successfulResponseHandler = jest.fn().mockResolvedValue(organizationUsersResponse);
const successfulResponseHandlerMultiplePages = jest.fn().mockResolvedValue({
  data: {
    organization: {
      id: organizationGid,
      organizationUsers: {
        nodes,
        pageInfo: pageInfoMultiplePages,
      },
    },
  },
});
const successfulResponseHandlerNoResults = jest.fn().mockResolvedValue({
  data: {
    organization: {
      id: organizationGid,
      organizationUsers: {
        nodes: [],
        pageInfo: pageInfoEmpty,
      },
    },
  },
});
const errorResponseHandler = jest.fn().mockRejectedValue(mockError);
const loadingResponseHandler = jest.fn().mockReturnValue(new Promise(() => {}));

describe('OrganizationsUsersApp', () => {
  let wrapper;
  let mockApollo;

  const createComponent = ({ handler = successfulResponseHandler } = {}) => {
    mockApollo = createMockApollo([[organizationUsersQuery, handler]]);

    wrapper = shallowMountExtended(OrganizationsUsersApp, {
      apolloProvider: mockApollo,
      provide: {
        organizationGid,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  const findOrganizationUsersView = () => wrapper.findComponent(OrganizationsUsersView);

  describe.each`
    description                                                     | handler                                   | loading  | userData                | expectedPageInfo         | error
    ${'when API call is loading'}                                   | ${loadingResponseHandler}                 | ${true}  | ${[]}                   | ${{}}                    | ${false}
    ${'when API returns successful with one page of results'}       | ${successfulResponseHandler}              | ${false} | ${MOCK_USERS_FORMATTED} | ${pageInfo}              | ${false}
    ${'when API returns successful with multiple pages of results'} | ${successfulResponseHandlerMultiplePages} | ${false} | ${MOCK_USERS_FORMATTED} | ${pageInfoMultiplePages} | ${false}
    ${'when API returns successful without results'}                | ${successfulResponseHandlerNoResults}     | ${false} | ${[]}                   | ${pageInfoEmpty}         | ${false}
    ${'when API returns error'}                                     | ${errorResponseHandler}                   | ${false} | ${[]}                   | ${{}}                    | ${true}
  `('$description', ({ handler, loading, userData, expectedPageInfo, error }) => {
    beforeEach(async () => {
      createComponent({ handler });
      await waitForPromises();
    });

    it(`renders OrganizationUsersView with loading prop set to ${loading}`, () => {
      expect(findOrganizationUsersView().props('loading')).toBe(loading);
    });

    it('renders OrganizationUsersView with correct users prop', () => {
      expect(findOrganizationUsersView().props('users')).toStrictEqual(userData);
    });

    it('renders OrganizationUsersView with correct pageInfo prop', () => {
      expect(findOrganizationUsersView().props('pageInfo')).toStrictEqual(expectedPageInfo);
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
    beforeEach(async () => {
      createComponent({ handler: successfulResponseHandlerMultiplePages });
      await waitForPromises();
    });

    it('handleNextPage calls organizationUsersQuery with correct pagination data', async () => {
      findOrganizationUsersView().vm.$emit('next');
      await waitForPromises();

      expect(successfulResponseHandlerMultiplePages).toHaveBeenCalledWith({
        id: organizationGid,
        before: '',
        after: pageInfoMultiplePages.endCursor,
        first: ORGANIZATION_USERS_PER_PAGE,
        last: null,
      });
    });

    it('handlePrevPage calls organizationUsersQuery with correct pagination data', async () => {
      findOrganizationUsersView().vm.$emit('prev');
      await waitForPromises();

      expect(successfulResponseHandlerMultiplePages).toHaveBeenCalledWith({
        id: organizationGid,
        before: pageInfoMultiplePages.startCursor,
        after: '',
        first: ORGANIZATION_USERS_PER_PAGE,
        last: null,
      });
    });
  });
});
