import { mountExtended } from 'jest/__helpers__/vue_test_utils_helper';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { SEARCH_MINIMUM_LENGTH } from '~/groups/constants';

let wrapper;

const defaultProvide = {
  newProjectPath: '/projects/new?namespace_id=231',
  newSubgroupPath: '/groups/new?parent_id=231',
  canCreateSubgroups: true,
  canCreateProjects: true,
};

const createComponent = ({ provide = {} } = {}) => {
  wrapper = mountExtended(SubgroupsAndProjectsEmptyState, {
    provide: {
      ...defaultProvide,
      ...provide,
    },
  });
};

const findNewSubgroupButton = () => wrapper.findByTestId('create-subgroup');
const findNewProjectButton = () => wrapper.findByTestId('create-project');
const findEmptyState = () => wrapper.findComponent(ResourceListsEmptyState);

describe('SubgroupsAndProjectsEmptyState', () => {
  describe('when user has permission to create a subgroup', () => {
    it('renders `Create subgroup` button', () => {
      createComponent();

      expect(findNewSubgroupButton().text()).toBe('Create subgroup');
      expect(findNewSubgroupButton().props()).toMatchObject({
        href: defaultProvide.newSubgroupPath,
        variant: 'default',
        category: 'secondary',
      });
    });
  });

  describe('when user has permission to create a subgroup but no permission to create a project', () => {
    it('renders `Create subgroup` button', () => {
      createComponent({ provide: { canCreateProjects: false } });

      expect(findNewSubgroupButton().props()).toMatchObject({
        variant: 'confirm',
        category: 'primary',
      });
    });
  });

  describe('when user has permission to create a project', () => {
    it('renders `Create new project` button', () => {
      createComponent();

      expect(findNewProjectButton().text()).toBe('Create project');
      expect(findNewProjectButton().props()).toMatchObject({
        href: defaultProvide.newProjectPath,
        variant: 'confirm',
        category: 'primary',
      });
    });
  });

  describe('when user has permissions', () => {
    it('renders correct title and description', () => {
      createComponent();

      expect(findEmptyState().props()).toMatchObject({
        title: 'Organize your work with projects and subgroups',
        description:
          'Use projects to store Git repositories and collaborate on issues. Use subgroups as folders to organize related projects and manage team access.',
      });
    });
  });

  describe('when user does not have permissions to create a project or a subgroup', () => {
    it('renders empty state', () => {
      createComponent({ provide: { canCreateSubgroups: false, canCreateProjects: false } });

      expect(findEmptyState().props()).toMatchObject({
        title: 'There are no subgroups or projects in this group',
        description:
          'You do not have necessary permissions to create a subgroup or project in this group. Please contact an owner of this group to create a new subgroup or project.',
        search: '',
        searchMinimumLength: SEARCH_MINIMUM_LENGTH,
      });

      expect(wrapper.findByTestId('empty-subgroup-and-projects-actions').exists()).toBe(false);
    });
  });
});
