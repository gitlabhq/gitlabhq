import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { organizations } from '~/organizations/mock_data';
import resolvers from '~/organizations/shared/graphql/resolvers';
import organizationsQuery from '~/organizations/index/graphql/organizations.query.graphql';
import OrganizationsIndexApp from '~/organizations/index/components/app.vue';
import OrganizationsView from '~/organizations/index/components/organizations_view.vue';
import { MOCK_NEW_ORG_URL } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('OrganizationsIndexApp', () => {
  let wrapper;
  let mockApollo;

  const createComponent = (mockResolvers = resolvers) => {
    mockApollo = createMockApollo([[organizationsQuery, mockResolvers]]);

    wrapper = shallowMountExtended(OrganizationsIndexApp, {
      apolloProvider: mockApollo,
      provide: {
        newOrganizationUrl: MOCK_NEW_ORG_URL,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  const findOrganizationHeaderText = () => wrapper.findByText('Organizations');
  const findNewOrganizationButton = () => wrapper.findComponent(GlButton);
  const findOrganizationsView = () => wrapper.findComponent(OrganizationsView);

  const loadingResolver = jest.fn().mockReturnValue(new Promise(() => {}));
  const successfulResolver = (nodes) =>
    jest.fn().mockResolvedValue({
      data: { currentUser: { id: 1, organizations: { nodes } } },
    });
  const errorResolver = jest.fn().mockRejectedValue('error');

  describe.each`
    description                                      | mockResolver                         | headerText | newOrgLink          | loading  | orgsData         | error
    ${'when API call is loading'}                    | ${loadingResolver}                   | ${true}    | ${MOCK_NEW_ORG_URL} | ${true}  | ${[]}            | ${false}
    ${'when API returns successful with results'}    | ${successfulResolver(organizations)} | ${true}    | ${MOCK_NEW_ORG_URL} | ${false} | ${organizations} | ${false}
    ${'when API returns successful without results'} | ${successfulResolver([])}            | ${false}   | ${false}            | ${false} | ${[]}            | ${false}
    ${'when API returns error'}                      | ${errorResolver}                     | ${false}   | ${false}            | ${false} | ${[]}            | ${true}
  `('$description', ({ mockResolver, headerText, newOrgLink, loading, orgsData, error }) => {
    beforeEach(async () => {
      createComponent(mockResolver);
      await waitForPromises();
    });

    it(`does ${headerText ? '' : 'not '}render the header text`, () => {
      expect(findOrganizationHeaderText().exists()).toBe(headerText);
    });

    it(`does ${newOrgLink ? '' : 'not '}render new organization button with correct link`, () => {
      expect(
        findNewOrganizationButton().exists() && findNewOrganizationButton().attributes('href'),
      ).toBe(newOrgLink);
    });

    it(`renders the organizations view with ${loading} loading prop`, () => {
      expect(findOrganizationsView().props('loading')).toBe(loading);
    });

    it(`renders the organizations view with ${
      orgsData ? 'correct' : 'empty'
    } organizations array prop`, () => {
      expect(findOrganizationsView().props('organizations')).toStrictEqual(orgsData);
    });

    it(`does ${error ? '' : 'not '}render an error message`, () => {
      return error
        ? expect(createAlert).toHaveBeenCalled()
        : expect(createAlert).not.toHaveBeenCalled();
    });
  });
});
