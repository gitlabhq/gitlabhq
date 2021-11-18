import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import OrganizationsRoot from '~/crm/components/organizations_root.vue';
import getGroupOrganizationsQuery from '~/crm/components/queries/get_group_organizations.query.graphql';
import { getGroupOrganizationsQueryResponse } from './mock_data';

jest.mock('~/flash');

describe('Customer relations organizations root app', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRowByName = (rowName) => wrapper.findAllByRole('row', { name: rowName });
  const successQueryHandler = jest.fn().mockResolvedValue(getGroupOrganizationsQueryResponse);

  const mountComponent = ({
    queryHandler = successQueryHandler,
    mountFunction = shallowMountExtended,
  } = {}) => {
    fakeApollo = createMockApollo([[getGroupOrganizationsQuery, queryHandler]]);
    wrapper = mountFunction(OrganizationsRoot, {
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

    expect(findRowByName(/Test Inc/i)).toHaveLength(1);
    expect(findRowByName(/VIP/i)).toHaveLength(1);
    expect(findRowByName(/120/i)).toHaveLength(1);
  });
});
