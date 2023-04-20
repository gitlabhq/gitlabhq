import { GlEmptyState } from '@gitlab/ui';

import { mountExtended } from 'jest/__helpers__/vue_test_utils_helper';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';

let wrapper;

const defaultProvide = {
  newProjectIllustration: '/assets/illustrations/project-create-new-sm.svg',
  newProjectPath: '/projects/new?namespace_id=231',
  newSubgroupIllustration: '/assets/illustrations/group-new.svg',
  newSubgroupPath: '/groups/new?parent_id=231',
  emptyProjectsIllustration: '/assets/illustrations/empty-state/empty-projects-md.svg',
  emptySubgroupIllustration: '/assets/illustrations/empty-state/empty-subgroup-md.svg',
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

const findNewSubgroupLink = () =>
  wrapper.findByRole('link', {
    name: new RegExp(SubgroupsAndProjectsEmptyState.i18n.withLinks.subgroup.title),
  });
const findNewProjectLink = () =>
  wrapper.findByRole('link', {
    name: new RegExp(SubgroupsAndProjectsEmptyState.i18n.withLinks.project.title),
  });
const findNewSubgroupIllustration = () =>
  wrapper.findByRole('img', { name: SubgroupsAndProjectsEmptyState.i18n.withLinks.subgroup.title });
const findNewProjectIllustration = () =>
  wrapper.findByRole('img', { name: SubgroupsAndProjectsEmptyState.i18n.withLinks.project.title });

describe('SubgroupsAndProjectsEmptyState', () => {
  describe('when user has permission to create a subgroup', () => {
    it('renders `Create new subgroup` link', () => {
      createComponent();

      expect(findNewSubgroupLink().attributes('href')).toBe(defaultProvide.newSubgroupPath);
      expect(findNewSubgroupIllustration().attributes('src')).toBe(
        defaultProvide.newSubgroupIllustration,
      );
    });
  });

  describe('when user has permission to create a project', () => {
    it('renders `Create new project` link', () => {
      createComponent();

      expect(findNewProjectLink().attributes('href')).toBe(defaultProvide.newProjectPath);
      expect(findNewProjectIllustration().attributes('src')).toBe(
        defaultProvide.newProjectIllustration,
      );
    });
  });

  describe('when user does not have permissions to create a project or a subgroup', () => {
    it('renders empty state', () => {
      createComponent({ provide: { canCreateSubgroups: false, canCreateProjects: false } });

      expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
        title: SubgroupsAndProjectsEmptyState.i18n.withoutLinks.title,
        description: SubgroupsAndProjectsEmptyState.i18n.withoutLinks.description,
        svgPath: defaultProvide.emptySubgroupIllustration,
      });
    });
  });
});
