import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import OrganizationGroupCard from '~/organizations/index/components/reconciliation/organization_group_card.vue';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';
import { mockGroup } from './mock_data';

describe('OrganizationGroupCard', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(OrganizationGroupCard, {
      propsData: {
        group: mockGroup,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findVisibilityIcon = () => wrapper.findByTestId('group-visibility');
  const findAllStats = () => wrapper.findAllComponents(ListItemStat);

  describe('template', () => {
    beforeEach(() => {
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
    });

    it('renders group name', () => {
      expect(wrapper.text()).toContain(mockGroup.fullName);
    });

    it('renders group stats', () => {
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

  describe('group visibility', () => {
    it.each`
      visibility    | expectedIcon | expectedTooltip
      ${'public'}   | ${'earth'}   | ${'Public - The group and any public projects can be viewed without any authentication.'}
      ${'private'}  | ${'lock'}    | ${'Private - The group and its projects can only be viewed by members.'}
      ${'internal'} | ${'shield'}  | ${'Internal - The group and any internal projects can be viewed by any logged in user except external users.'}
    `(
      'renders $visibility visibility icon and tooltip',
      ({ visibility, expectedIcon, expectedTooltip }) => {
        createComponent({ props: { group: { ...mockGroup, visibility } } });

        const icon = findVisibilityIcon();

        expect(icon.props('name')).toBe(expectedIcon);
        expect(getBinding(icon.element, 'gl-tooltip').value).toBe(expectedTooltip);
      },
    );
  });
});
