import { GlTableLite } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiAnalyticsList from '~/ci/catalog/components/list/ci_analytics_list.vue';
import { catalogResponseBody } from '../../mock';

describe('CiAnalyticsList', () => {
  let wrapper;

  const { nodes } = catalogResponseBody.data.ciCatalogResources;
  const defaultProps = {
    resources: [nodes[0]],
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(CiAnalyticsList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders table with correct fields', () => {
    expect(findTable().props('fields')).toHaveLength(3);
  });

  it('provides resources data to the table', () => {
    const resource = nodes[0];
    const expectedItems = [
      {
        name: resource.name,
        detailsPath: { name: 'ci_resources_details', params: { id: resource.fullPath } },
        latestVersion: 'Unreleased',
        usageStatistics: `${resource.last30DayUsageCount} projects`,
        components: '',
      },
    ];
    expect(findTable().props('items')).toMatchObject(expectedItems);
  });
});
