import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContactsRoot from '~/crm/contacts/components/contacts_root.vue';
import getGroupContactsQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import getGroupContactsCountByStateQuery from '~/crm/contacts/components/graphql/get_group_contacts_count_by_state.graphql';
import PaginatedTableWithSearchAndTabs from '~/vue_shared/components/paginated_table_with_search_and_tabs/paginated_table_with_search_and_tabs.vue';
import { getGroupContactsQueryResponse, getGroupContactsCountQueryResponse } from './mock_data';

Vue.use(VueApollo);

describe('Customer relations contacts root app', () => {
  let wrapper;
  let fakeApollo;

  const findOrganizationsLink = () => wrapper.findByTestId('organizations-link');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNewContactButton = () => wrapper.findByTestId('new-contact-button');
  const findTable = () => wrapper.findComponent(PaginatedTableWithSearchAndTabs);
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupContactsQueryResponse);
  const successCountQueryHandler = jest.fn().mockResolvedValue(getGroupContactsCountQueryResponse);

  const mountComponent = ({
    queryHandler = successQueryHandler,
    countQueryHandler = successCountQueryHandler,
    canAdminCrmContact = true,
    canReadCrmOrganization = true,
    textQuery = null,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getGroupContactsQuery, queryHandler],
      [getGroupContactsCountByStateQuery, countQueryHandler],
    ]);
    wrapper = shallowMountExtended(ContactsRoot, {
      provide: {
        groupFullPath: 'flightjs',
        groupId: 26,
        groupIssuesPath: '/issues',
        groupOrganizationsPath: '/organizations',
        canAdminCrmContact,
        canReadCrmOrganization,
        textQuery,
      },
      apolloProvider: fakeApollo,
      stubs: ['router-link', 'router-view'],
    });
  };

  it('should render table with default props and loading state', () => {
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
      trackViewsOptions: { category: 'Customer Relations', action: 'view_contacts_list' },
      i18n: {
        emptyText: 'No contacts found',
        issuesButtonLabel: 'View issues',
        editButtonLabel: 'Edit',
        title: 'Customer relations contacts',
        newContact: 'New contact',
        errorMsg: 'Something went wrong. Please try again.',
      },
      serverErrorMessage: '',
      filterSearchKey: 'contacts',
      filterSearchTokens: [],
    });
    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('organizations link', () => {
    it('renders when canReadCrmOrganization is true', () => {
      mountComponent();

      expect(findOrganizationsLink().attributes('href')).toBe('/organizations');
    });

    it('does not render when canReadCrmOrganization is false', () => {
      mountComponent({ canReadCrmOrganization: false });

      expect(findOrganizationsLink().exists()).toBe(false);
    });
  });

  describe('new contact button', () => {
    it('should exist when user has permission', () => {
      mountComponent();

      expect(findNewContactButton().exists()).toBe(true);
    });

    it('should not exist when user has no permission', () => {
      mountComponent({ canAdminCrmContact: false });

      expect(findNewContactButton().exists()).toBe(false);
    });
  });

  describe('error', () => {
    it('should exist on reject', async () => {
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
        getGroupContactsQueryResponse.data.group.contacts.nodes,
      );
    });
  });
});
