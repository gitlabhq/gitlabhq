import { GlEmptyState } from '@gitlab/ui';

import { mountExtended } from 'jest/__helpers__/vue_test_utils_helper';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';

let wrapper;

const defaultProvide = {
  newProjectPath: '/projects/new?namespace_id=231',
  newSubgroupPath: '/groups/new?parent_id=231',
  emptyProjectsIllustration: '/assets/illustrations/empty-state/empty-projects-md.svg',
  emptySubgroupIllustration: '/assets/illustrations/empty-state/empty-projects-md.svg',
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

const findNewSubgroupCard = () => wrapper.findByTestId('create-subgroup');
const findNewProjectCard = () => wrapper.findByTestId('create-project');

describe('SubgroupsAndProjectsEmptyState', () => {
  describe('when user has permission to create a subgroup', () => {
    it('renders `Create subgroup` card', () => {
      createComponent();

      expect(findNewSubgroupCard().props()).toMatchObject({
        title: 'Create subgroup',
        description: 'Use groups to manage multiple projects and members.',
        icon: 'subgroup',
        href: defaultProvide.newSubgroupPath,
      });
    });
  });

  describe('when user has permission to create a project', () => {
    it('renders `Create new project` link', () => {
      createComponent();

      expect(findNewProjectCard().props()).toMatchObject({
        title: 'Create project',
        description:
          'Use projects to store and access issues, wiki pages, and other GitLab features.',
        icon: 'project',
        href: defaultProvide.newProjectPath,
      });
    });
  });

  describe('when user does not have permissions to create a project or a subgroup', () => {
    it('renders empty state', () => {
      createComponent({ provide: { canCreateSubgroups: false, canCreateProjects: false } });

      expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
        title: 'There are no subgroups or projects in this group',
        description:
          'You do not have necessary permissions to create a subgroup or project in this group. Please contact an owner of this group to create a new subgroup or project.',
        svgPath: defaultProvide.emptySubgroupIllustration,
      });

      expect(wrapper.findByTestId('empty-subgroup-and-projects-actions').exists()).toBe(false);
    });
  });
});
