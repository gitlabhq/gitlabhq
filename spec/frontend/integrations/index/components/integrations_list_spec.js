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

  it('provides correct `integrations` prop to the IntegrationsTable instance', () => {
    createComponent({ integrations: [...mockInactiveIntegrations, ...mockActiveIntegrations] });

    expect(findActiveIntegrationsTable().props('integrations')).toEqual(mockActiveIntegrations);
    expect(findInactiveIntegrationsTable().props('integrations')).toEqual(mockInactiveIntegrations);
    expect(findInactiveIntegrationsTable().props('inactive')).toBe(true);
  });
  it('filters out Amazon Q integration from this page since it is rendered in General Settings', () => {
    const amazonQintegration = {
      active: true,
      configured: true,
      title: 'Amazon Q',
      description: 'Amazon Q integration',
      updated_at: '2021-03-18T00:27:09.634Z',
      edit_path:
        '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/amazon_q/edit',
      name: 'amazon_q',
    };
    const mockActiveIntegrationsWithAmazonQ = [...mockActiveIntegrations, amazonQintegration];
    createComponent({
      integrations: [...mockInactiveIntegrations, ...mockActiveIntegrationsWithAmazonQ],
    });

    expect(findActiveIntegrationsTable().props('integrations')).toEqual(mockActiveIntegrations);
    expect(findInactiveIntegrationsTable().props('integrations')).toEqual(mockInactiveIntegrations);
    expect(findInactiveIntegrationsTable().props('inactive')).toBe(true);
  });
});
