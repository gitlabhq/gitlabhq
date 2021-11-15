import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import ContactsRoot from '~/crm/components/contacts_root.vue';
import getGroupContactsQuery from '~/crm/components/queries/get_group_contacts.query.graphql';
import { getGroupContactsQueryResponse } from './mock_data';

jest.mock('~/flash');

describe('Customer relations contacts root app', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRowByName = (rowName) => wrapper.findAllByRole('row', { name: rowName });
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupContactsQueryResponse);

  const mountComponent = ({
    queryHandler = successQueryHandler,
    mountFunction = shallowMountExtended,
  } = {}) => {
    fakeApollo = createMockApollo([[getGroupContactsQuery, queryHandler]]);
    wrapper = mountFunction(ContactsRoot, {
      provide: { groupFullPath: 'flightjs' },
      apolloProvider: fakeApollo,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('should render loading spinner', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('should render error message on reject', async () => {
    mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });

  it('renders correct results', async () => {
    mountComponent({ mountFunction: mountExtended });
    await waitForPromises();

    expect(findRowByName(/Marty/i)).toHaveLength(1);
    expect(findRowByName(/George/i)).toHaveLength(1);
    expect(findRowByName(/jd@gitlab.com/i)).toHaveLength(1);
  });
});
