import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/show/components/app.vue';
import OrganizationAvatar from '~/organizations/show/components/organization_avatar.vue';
import OrganizationDescription from '~/organizations/show/components/organization_description.vue';
import GroupsAndProjects from '~/organizations/show/components/groups_and_projects.vue';
import AssociationCounts from '~/organizations/show/components/association_counts.vue';

describe('OrganizationShowApp', () => {
  let wrapper;

  const defaultPropsData = {
    organization: {
      id: 1,
      name: 'GitLab',
    },
    associationCounts: {
      groups: 10,
      projects: 5,
      users: 6,
    },
    groupsAndProjectsOrganizationPath: '/-/organizations/default/groups_and_projects',
    usersOrganizationPath: '/-/organizations/default/users',
  };

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(App, { propsData: { ...defaultPropsData, ...propsData } });
  };

  const findAssociationsCount = () => wrapper.findComponent(AssociationCounts);

  it('renders organization avatar and passes organization prop', () => {
    createComponent();

    expect(wrapper.findComponent(OrganizationAvatar).props('organization')).toEqual(
      defaultPropsData.organization,
    );
  });

  it('renders organization description and passes organization prop', () => {
    createComponent();

    expect(wrapper.findComponent(OrganizationDescription).props('organization')).toEqual(
      defaultPropsData.organization,
    );
  });

  it('renders groups and projects component and passes `groupsAndProjectsOrganizationPath` prop', () => {
    createComponent();

    expect(
      wrapper.findComponent(GroupsAndProjects).props('groupsAndProjectsOrganizationPath'),
    ).toEqual(defaultPropsData.groupsAndProjectsOrganizationPath);
  });

  describe('when association counts are available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders association counts component and passes expected props', () => {
      expect(findAssociationsCount().props()).toEqual({
        associationCounts: defaultPropsData.associationCounts,
        groupsAndProjectsOrganizationPath: defaultPropsData.groupsAndProjectsOrganizationPath,
        usersOrganizationPath: defaultPropsData.usersOrganizationPath,
      });
    });
  });

  describe('when association counts are not available', () => {
    beforeEach(() => {
      createComponent({ propsData: { associationCounts: {} } });
    });

    it('does not render association counts component', () => {
      expect(findAssociationsCount().exists()).toBe(false);
    });
  });
});
