import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AssociationCounts from '~/organizations/show/components/association_counts.vue';
import AssociationCountCard from '~/organizations/show/components/association_count_card.vue';

describe('AssociationCounts', () => {
  let wrapper;

  const defaultPropsData = {
    associationCounts: {
      groups: '10',
      projects: '5',
      users: '1000+',
    },
    groupsAndProjectsOrganizationPath: '/-/organizations/default/groups_and_projects',
    usersOrganizationPath: '/-/organizations/default/users',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(AssociationCounts, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findAssociationCountCardAt = (index) =>
    wrapper.findAllComponents(AssociationCountCard).at(index);

  it('renders groups association count card', () => {
    createComponent();

    expect(findAssociationCountCardAt(0).props()).toEqual({
      title: 'Groups',
      iconName: 'group',
      count: defaultPropsData.associationCounts.groups,
      linkText: 'View all',
      linkHref: '/-/organizations/default/groups_and_projects?display=groups',
    });
  });

  it('renders projects association count card', () => {
    createComponent();

    expect(findAssociationCountCardAt(1).props()).toEqual({
      title: 'Projects',
      iconName: 'project',
      count: defaultPropsData.associationCounts.projects,
      linkText: 'View all',
      linkHref: '/-/organizations/default/groups_and_projects?display=projects',
    });
  });

  it('renders users association count card', () => {
    createComponent();

    expect(findAssociationCountCardAt(2).props()).toEqual({
      title: 'Users',
      iconName: 'users',
      count: defaultPropsData.associationCounts.users,
      linkText: 'Manage',
      linkHref: '/-/organizations/default/users',
    });
  });
});
