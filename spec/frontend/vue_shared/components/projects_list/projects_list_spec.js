import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('ProjectsList', () => {
  let wrapper;

  const defaultPropsData = {
    projects: convertObjectPropsToCamelCase(projects, { deep: true }),
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

    expect(expectedProps).toEqual(
      defaultPropsData.projects.map((project) => ({
        project,
      })),
    );
  });
});
