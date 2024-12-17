import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';

describe('ProjectsList', () => {
  let wrapper;

  const defaultPropsData = {
    projects: convertObjectPropsToCamelCase(projects, { deep: true }),
    listItemClass: 'gl-px-5',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ProjectsList, {
      propsData: defaultPropsData,
    });
  };

  it('renders list with `ProjectListItem` component', () => {
    createComponent();

    const projectsListItemWrappers = wrapper.findAllComponents(ProjectsListItem).wrappers;
    const expectedProps = projectsListItemWrappers.map((projectsListItemWrapper) =>
      projectsListItemWrapper.props(),
    );
    const expectedClasses = projectsListItemWrappers.map((projectsListItemWrapper) =>
      projectsListItemWrapper.classes(),
    );

    expect(expectedProps).toEqual(
      defaultPropsData.projects.map((project) => ({
        project,
        showProjectIcon: false,
        timestampType: TIMESTAMP_TYPE_CREATED_AT,
      })),
    );
    expect(expectedClasses).toEqual(
      defaultPropsData.projects.map(() => [defaultPropsData.listItemClass]),
    );
  });

  describe('when `ProjectListItem` emits `refetch` event', () => {
    beforeEach(() => {
      createComponent();

      wrapper.findComponent(ProjectsListItem).vm.$emit('refetch');
    });

    it('emits `refetch` event', () => {
      expect(wrapper.emitted('refetch')).toEqual([[]]);
    });
  });
});
