import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationGroupStats from '~/groups/settings/create_organization/components/organization_group_stats.vue';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';
import { mockGroup } from './mock_data';

describe('OrganizationGroupStats', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(OrganizationGroupStats, {
      propsData: {
        group: mockGroup,
        ...props,
      },
    });
  };

  const findAllStats = () => wrapper.findAllComponents(ListItemStat);

  it('renders group stats with metric prefixed counts', () => {
    createComponent({
      props: {
        group: {
          ...mockGroup,
          descendantGroupsCount: 1200,
          projectsCount: 10500,
          groupMembersCount: 1500000,
        },
      },
    });

    const stats = findAllStats();

    expect(stats.at(0).props()).toMatchObject({
      tooltipText: 'Subgroups',
      iconName: 'subgroup',
      stat: '1.2k',
    });

    expect(stats.at(1).props()).toMatchObject({
      tooltipText: 'Projects',
      iconName: 'project',
      stat: '10.5k',
    });

    expect(stats.at(2).props()).toMatchObject({
      tooltipText: 'Direct members',
      iconName: 'users',
      stat: '1.5m',
    });
  });
});
