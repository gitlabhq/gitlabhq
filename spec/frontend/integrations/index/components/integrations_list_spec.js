import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import IntegrationsList from '~/integrations/index/components/integrations_list.vue';
import { mockActiveIntegrations, mockInactiveIntegrations } from '../mock_data';

describe('IntegrationsList', () => {
  let wrapper;

  const findActiveIntegrationsTable = () => wrapper.findByTestId('active-integrations-table');
  const findInactiveIntegrationsTable = () => wrapper.findByTestId('inactive-integrations-table');

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(IntegrationsList, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('provides correct `integrations` prop to the IntegrationsTable instance', () => {
    createComponent({ integrations: [...mockInactiveIntegrations, ...mockActiveIntegrations] });

    expect(findActiveIntegrationsTable().props('integrations')).toEqual(mockActiveIntegrations);
    expect(findInactiveIntegrationsTable().props('integrations')).toEqual(mockInactiveIntegrations);
  });
});
