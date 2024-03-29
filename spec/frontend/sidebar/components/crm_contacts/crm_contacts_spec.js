import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CrmContacts from '~/sidebar/components/crm_contacts/crm_contacts.vue';
import getIssueCrmContactsQuery from '~/sidebar/queries/get_issue_crm_contacts.query.graphql';
import issueCrmContactsSubscription from '~/sidebar/queries/issue_crm_contacts.subscription.graphql';
import {
  getIssueCrmContactsQueryResponse,
  getIssueCrmContactsQueryResponseEmpty,
  issueCrmContactsUpdateResponse,
  issueCrmContactsUpdateNullResponse,
} from '../mock_data';

jest.mock('~/alert');

describe('Issue crm contacts component', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;

  const successQueryHandler = jest.fn().mockResolvedValue(getIssueCrmContactsQueryResponse);
  const emptySuccessQueryHandler = jest
    .fn()
    .mockResolvedValue(getIssueCrmContactsQueryResponseEmpty);
  const successSubscriptionHandler = jest.fn().mockResolvedValue(issueCrmContactsUpdateResponse);
  const nullSubscriptionHandler = jest.fn().mockResolvedValue(issueCrmContactsUpdateNullResponse);

  const mountComponent = ({
    queryHandler = successQueryHandler,
    subscriptionHandler = successSubscriptionHandler,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getIssueCrmContactsQuery, queryHandler],
      [issueCrmContactsSubscription, subscriptionHandler],
    ]);
    wrapper = shallowMountExtended(CrmContacts, {
      propsData: { issueId: '123', groupIssuesPath: '/groups/flightjs/-/issues' },
      apolloProvider: fakeApollo,
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  it('should render error message on reject', async () => {
    mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  it('calls the query with correct variables', () => {
    mountComponent();

    expect(successQueryHandler).toHaveBeenCalledWith({
      id: 'gid://gitlab/Issue/123',
    });
  });

  it('calls the subscription with correct variable for issue', () => {
    mountComponent();

    expect(successSubscriptionHandler).toHaveBeenCalledWith({
      id: 'gid://gitlab/Issue/123',
    });
  });

  it('renders correct initial results', async () => {
    mountComponent({ subscriptionHandler: nullSubscriptionHandler });
    await waitForPromises();

    expect(wrapper.find('#contact_0').text()).toContain('Someone Important');
    expect(wrapper.find('#contact_0').attributes('href')).toBe(
      '/groups/flightjs/-/issues?crm_contact_id=1',
    );
    expect(wrapper.find('#contact_container_0').text()).toContain('si@gitlab.com');
    expect(wrapper.find('#contact_1').text()).toContain('Marty McFly');
    expect(wrapper.find('#contact_1').attributes('href')).toBe(
      '/groups/flightjs/-/issues?crm_contact_id=5',
    );
  });

  it('has an empty state', async () => {
    mountComponent({
      queryHandler: emptySuccessQueryHandler,
      subscriptionHandler: nullSubscriptionHandler,
    });
    await waitForPromises();

    expect(wrapper.findByTestId('crm-empty-message').exists()).toBe(true);
  });

  it('renders correct results after subscription update', async () => {
    mountComponent();
    await waitForPromises();

    const contact = ['Dave Davies', 'dd@gitlab.com', '+44 20 1111 2222', 'Vice President'];
    contact.forEach((property) => {
      expect(wrapper.find('#contact_container_0').text()).toContain(property);
    });
    expect(wrapper.find('#contact_0').attributes('href')).toBe(
      '/groups/flightjs/-/issues?crm_contact_id=13',
    );
  });
});
