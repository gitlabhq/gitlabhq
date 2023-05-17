import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OrganizationsRoot from '~/crm/organizations/components/organizations_root.vue';
import routes from '~/crm/organizations/routes';
import getGroupOrganizationsQuery from '~/crm/organizations/components/graphql/get_group_organizations.query.graphql';
import getGroupOrganizationsCountByStateQuery from '~/crm/organizations/components/graphql/get_group_organizations_count_by_state.query.graphql';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import {
  getGroupOrganizationsQueryResponse,
  getGroupOrganizationsCountQueryResponse,
} from './mock_data';

describe('Customer relations organizations root app', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);
  let wrapper;
  let fakeApollo;
  let router;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRowByName = (rowName) => wrapper.findAllByRole('row', { name: rowName });
  const findIssuesLinks = () => wrapper.findAllByTestId('issues-link');
  const findNewOrganizationButton = () => wrapper.findByTestId('new-organization-button');
  const findTable = () => wrapper.findComponent(PaginatedTableWithSearchAndTabs);
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupOrganizationsQueryResponse);
  const successCountQueryHandler = jest
    .fn()
    .mockResolvedValue(getGroupOrganizationsCountQueryResponse);

  const basePath = '/groups/flightjs/-/crm/organizations';

  const mountComponent = ({
    queryHandler = successQueryHandler,
    countQueryHandler = successCountQueryHandler,
    canAdminCrmOrganization = true,
    textQuery = null,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getGroupOrganizationsQuery, queryHandler],
      [getGroupOrganizationsCountByStateQuery, countQueryHandler],
    ]);
    wrapper = mountExtended(OrganizationsRoot, {
      router,
      provide: {
        canAdminCrmOrganization,
        groupFullPath: 'flightjs',
        groupIssuesPath: '/issues',
        textQuery,
      },
      apolloProvider: fakeApollo,
    });
  };

  beforeEach(() => {
    router = new VueRouter({
      base: basePath,
      mode: 'history',
      routes,
    });
  });

  afterEach(() => {
    fakeApollo = null;
    router = null;
  });

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

      expect(wrapper.text()).toContain('Something went wrong. Please try again.');
    });

    it('should be removed on error-alert-dismissed event', async () => {
      mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
      await waitForPromises();

      expect(wrapper.text()).toContain('Something went wrong. Please try again.');

      findTable().vm.$emit('error-alert-dismissed');
      await waitForPromises();

      expect(wrapper.text()).not.toContain('Something went wrong. Please try again.');
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

      expect(findRowByName(/Test Inc/i)).toHaveLength(1);
      expect(findRowByName(/VIP/i)).toHaveLength(1);
      expect(findRowByName(/120/i)).toHaveLength(1);

      expect(findIssuesLinks()).toHaveLength(3);

      const links = findIssuesLinks().wrappers.map((w) => w.attributes('href'));
      expect(links).toEqual(
        expect.arrayContaining([
          '/issues?crm_organization_id=1',
          '/issues?crm_organization_id=2',
          '/issues?crm_organization_id=3',
        ]),
      );
    });
  });
});
