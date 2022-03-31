import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContactsRoot from '~/crm/contacts/components/contacts_root.vue';
import getGroupContactsQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import routes from '~/crm/contacts/routes';
import { getGroupContactsQueryResponse } from './mock_data';

describe('Customer relations contacts root app', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);
  let wrapper;
  let fakeApollo;
  let router;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRowByName = (rowName) => wrapper.findAllByRole('row', { name: rowName });
  const findIssuesLinks = () => wrapper.findAllByTestId('issues-link');
  const findNewContactButton = () => wrapper.findByTestId('new-contact-button');
  const findError = () => wrapper.findComponent(GlAlert);
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupContactsQueryResponse);

  const basePath = '/groups/flightjs/-/crm/contacts';

  const mountComponent = ({
    queryHandler = successQueryHandler,
    mountFunction = shallowMountExtended,
    canAdminCrmContact = true,
  } = {}) => {
    fakeApollo = createMockApollo([[getGroupContactsQuery, queryHandler]]);
    wrapper = mountFunction(ContactsRoot, {
      router,
      provide: {
        groupFullPath: 'flightjs',
        groupId: 26,
        groupIssuesPath: '/issues',
        canAdminCrmContact,
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
    wrapper.destroy();
    fakeApollo = null;
    router = null;
  });

  it('should render loading spinner', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
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

      expect(findError().exists()).toBe(true);
    });
  });

  describe('on successful load', () => {
    it('should not render error', async () => {
      mountComponent();
      await waitForPromises();

      expect(findError().exists()).toBe(false);
    });

    it('renders correct results', async () => {
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();

      expect(findRowByName(/Marty/i)).toHaveLength(1);
      expect(findRowByName(/George/i)).toHaveLength(1);
      expect(findRowByName(/jd@gitlab.com/i)).toHaveLength(1);

      const issueLink = findIssuesLinks().at(0);
      expect(issueLink.exists()).toBe(true);
      expect(issueLink.attributes('href')).toBe('/issues?scope=all&state=opened&crm_contact_id=16');
    });
  });
});
