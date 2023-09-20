import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/show/components/app.vue';
import OrganizationAvatar from '~/organizations/show/components/organization_avatar.vue';
import GroupsAndProjects from '~/organizations/show/components/groups_and_projects.vue';
import AssociationCount from '~/organizations/show/components/association_counts.vue';

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
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(App, { propsData: defaultPropsData });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders organization avatar and passes organization prop', () => {
    expect(wrapper.findComponent(OrganizationAvatar).props('organization')).toEqual(
      defaultPropsData.organization,
    );
  });

  it('renders groups and projects component and passes `groupsAndProjectsOrganizationPath` prop', () => {
    expect(
      wrapper.findComponent(GroupsAndProjects).props('groupsAndProjectsOrganizationPath'),
    ).toEqual(defaultPropsData.groupsAndProjectsOrganizationPath);
  });

  it('renders associations count component and passes expected props', () => {
    expect(wrapper.findComponent(AssociationCount).props()).toEqual({
      associationCounts: defaultPropsData.associationCounts,
      groupsAndProjectsOrganizationPath: defaultPropsData.groupsAndProjectsOrganizationPath,
    });
  });
});
