import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OrganizationsRoot from '~/crm/organizations/components/organizations_root.vue';
import getGroupOrganizationsQuery from '~/crm/organizations/components/graphql/get_group_organizations.query.graphql';
import getGroupOrganizationsCountByStateQuery from '~/crm/organizations/components/graphql/get_group_organizations_count_by_state.query.graphql';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import {
  getGroupOrganizationsQueryResponse,
  getGroupOrganizationsCountQueryResponse,
} from './mock_data';

Vue.use(VueApollo);

describe('Customer relations organizations root app', () => {
  let wrapper;
  let fakeApollo;

  const findContactsLink = () => wrapper.findByTestId('contacts-link');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNewOrganizationButton = () => wrapper.findByTestId('new-organization-button');
  const findTable = () => wrapper.findComponent(PaginatedTableWithSearchAndTabs);
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupOrganizationsQueryResponse);
  const successCountQueryHandler = jest
    .fn()
    .mockResolvedValue(getGroupOrganizationsCountQueryResponse);

  const mountComponent = ({
    queryHandler = successQueryHandler,
    countQueryHandler = successCountQueryHandler,
    canAdminCrmOrganization = true,
    canReadCrmContact = true,
    textQuery = null,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getGroupOrganizationsQuery, queryHandler],
      [getGroupOrganizationsCountByStateQuery, countQueryHandler],
    ]);
    wrapper = shallowMountExtended(OrganizationsRoot, {
      provide: {
        canAdminCrmOrganization,
        canReadCrmContact,
        groupContactsPath: '/contacts',
        groupFullPath: 'flightjs',
        groupIssuesPath: '/issues',
        textQuery,
      },
      apolloProvider: fakeApollo,
      stubs: ['router-link', 'router-view'],
    });
  };

  it('should render table with default props and loading spinner', () => {
    mountComponent();

    expect(findTable().props()).toMatchObject({
      items: [],
      itemsCount: {},
      pageInfo: {},
      statusTabs: [
        { title: 'Active', status: 'ACTIVE', filters: 'active' },
        { title: 'Inactive', status: 'INACTIVE', filters: 'inactive' },
        { title: 'All', status: 'ALL', filters: 'all' },
      ],
      showItems: true,
      showErrorMsg: false,
      trackViewsOptions: { category: 'Customer Relations', action: 'view_organizations_list' },
      i18n: {
        emptyText: 'No organizations found',
        issuesButtonLabel: 'View issues',
        editButtonLabel: 'Edit',
        title: 'Customer relations organizations',
        newOrganization: 'New organization',
        errorMsg: 'Something went wrong. Please try again.',
      },
      serverErrorMessage: '',
      filterSearchKey: 'organizations',
      filterSearchTokens: [],
    });
    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('contacts link', () => {
    it('renders when canReadContact is true', () => {
      mountComponent();

      expect(findContactsLink().attributes('href')).toBe('/contacts');
    });

    it('does not render when canReadContact is false', () => {
      mountComponent({ canReadCrmContact: false });

      expect(findContactsLink().exists()).toBe(false);
    });
  });

  describe('new organization button', () => {
    it('should exist when user has permission', () => {
      mountComponent();

      expect(findNewOrganizationButton().exists()).toBe(true);
    });

    it('should not exist when user has no permission', () => {
      mountComponent({ canAdminCrmOrganization: false });

      expect(findNewOrganizationButton().exists()).toBe(false);
    });
  });

  describe('error', () => {
    it('should render on reject', async () => {
      mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
      await waitForPromises();

      expect(findTable().props('showErrorMsg')).toBe(true);
    });

    it('should be removed on error-alert-dismissed event', async () => {
      mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
      await waitForPromises();

      expect(findTable().props('showErrorMsg')).toBe(true);

      findTable().vm.$emit('error-alert-dismissed');
      await waitForPromises();

      expect(findTable().props('showErrorMsg')).toBe(false);
    });
  });

  describe('on successful load', () => {
    it('should not render error', async () => {
      mountComponent();
      await waitForPromises();

      expect(wrapper.text()).not.toContain('Something went wrong. Please try again.');
    });

    it('renders correct results', async () => {
      mountComponent();
      await waitForPromises();

      expect(findTable().props('items')).toEqual(
        getGroupOrganizationsQueryResponse.data.group.organizations.nodes,
      );
    });
  });
});
