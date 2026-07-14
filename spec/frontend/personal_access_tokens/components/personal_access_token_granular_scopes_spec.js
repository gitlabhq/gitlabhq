import { GlIcon, GlLink, GlButton, GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import PersonalAccessTokenGranularScopes from '~/personal_access_tokens/components/personal_access_token_granular_scopes.vue';
import {
  mockGranularGroupScope,
  mockGranularProjectScope,
  mockGranularUserScope,
  mockGranularInstanceScope,
} from '../mock_data';

describe('PersonalAccessTokenGranularScopes', () => {
  let wrapper;

  const createComponent = ({ scopes = [mockGranularGroupScope] } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenGranularScopes, {
      propsData: { scopes },
    });
  };

  const findProjectAvatar = () => wrapper.findComponent(ProjectAvatar);
  const findDescendantCounts = () => wrapper.findByTestId('descendant-counts');
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findIcons = () => wrapper.findAllComponents(GlIcon);

  const findToggleButtons = () => wrapper.findAllComponents(GlButton);
  const findGroupToggleButton = () => findToggleButtons().at(0);
  const findUserToggleButton = () => findToggleButtons().at(1);
  const findInstanceToggleButton = () => findToggleButtons().at(2);

  const findCollapses = () => wrapper.findAllComponents(GlCollapse);
  const findGroupCollapse = () => findCollapses().at(0);
  const findUserCollapse = () => findCollapses().at(1);
  const findInstanceCollapse = () => findCollapses().at(2);

  describe('group access descriptions', () => {
    it('renders personal projects description', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, access: 'PERSONAL_PROJECTS' }],
      });

      expect(wrapper.text()).toContain('Group and project access');
      expect(wrapper.text()).toContain('Only my personal projects, including future ones');
    });

    it('renders selected memberships description', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, access: 'SELECTED_MEMBERSHIPS' }],
      });

      expect(wrapper.text()).toContain('Group and project access');
      expect(wrapper.text()).toContain("Only specific group or projects that I'm a member of");
    });

    it('renders all memberships description', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, access: 'ALL_MEMBERSHIPS' }],
      });

      expect(wrapper.text()).toContain('Group and project access');
      expect(wrapper.text()).toContain(
        "All groups and projects that I'm a member of, including future ones",
      );
    });

    it('does not render when only user scopes are present', () => {
      createComponent({
        scopes: [mockGranularUserScope],
      });

      expect(wrapper.text()).not.toContain('Group and project access');
    });
  });

  describe('namespace', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders namespace when scoped on group', () => {
      expect(findProjectAvatar().exists()).toBe(true);
      expect(findProjectAvatar().props()).toMatchObject({
        projectId: mockGranularGroupScope.namespace.id,
        projectName: mockGranularGroupScope.namespace.fullName,
        projectAvatarUrl: mockGranularGroupScope.namespace.avatarUrl,
        size: 24,
      });
    });

    it('renders link to namespace', () => {
      expect(findLinks().at(0).attributes('href')).toBe(mockGranularGroupScope.group.webUrl);
      expect(findLinks().at(0).text()).toBe(mockGranularGroupScope.group.fullPath);
    });

    it('renders group icon for namespace', () => {
      expect(findIcons().at(0).props()).toMatchObject({
        name: 'group',
      });
    });

    it('renders descendant counts for a group scope', () => {
      expect(findDescendantCounts().text()).toBe('2 subgroups, 5 projects');
    });

    it('does not render descendant counts when they are unavailable', () => {
      createComponent({
        scopes: [
          {
            ...mockGranularGroupScope,
            group: {
              ...mockGranularGroupScope.group,
              projectsCount: null,
              descendantGroupsCount: null,
            },
          },
        ],
      });

      expect(findDescendantCounts().exists()).toBe(false);
    });

    it('renders multiple namespaces when multiple `SELECTED_MEMBERSHIPS` scopes are provided', () => {
      createComponent({ scopes: [mockGranularGroupScope, mockGranularProjectScope] });

      expect(wrapper.findAllComponents(ProjectAvatar)).toHaveLength(2);

      expect(findLinks().at(0).text()).toBe(mockGranularGroupScope.group.fullPath);
      expect(findLinks().at(1).text()).toBe(mockGranularProjectScope.project.fullPath);
    });

    it('handles scope without namespace', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, namespace: null, group: null, project: null }],
      });

      expect(findProjectAvatar().exists()).toBe(false);
    });
  });

  describe('permissions', () => {
    beforeEach(() => {
      createComponent({
        scopes: [mockGranularGroupScope, mockGranularUserScope, mockGranularInstanceScope],
      });
    });

    it('renders group permissions toggle', () => {
      expect(findGroupToggleButton().text()).toContain('Group and project permissions (4)');
    });

    it('renders user permissions toggle', () => {
      expect(findUserToggleButton().text()).toContain('User permissions (2)');
    });

    it('renders global (instance) permissions toggle', () => {
      expect(findInstanceToggleButton().text()).toContain('Global permissions (1)');
    });

    it('renders global permissions with their categories, resources and actions', () => {
      expect(findInstanceCollapse().text()).toContain('Application security');
      expect(findInstanceCollapse().text()).toContain('Compliance policy setting: Read');
    });

    it('does not render namespace access description for instance scopes', () => {
      createComponent({ scopes: [mockGranularInstanceScope] });

      expect(wrapper.text()).not.toContain('Group and project access');
    });

    it('renders group permissions with their categories, resources and actions', () => {
      expect(findGroupCollapse().text()).toContain('Groups and projects');
      expect(findGroupCollapse().text()).toContain('Project: Read, Write');
      expect(findGroupCollapse().text()).toContain('Contributed project: Read');

      expect(findGroupCollapse().text()).toContain('Merge request');
      expect(findGroupCollapse().text()).toContain('Repository: Read');
    });

    it('renders user permissions with their categories, resources and actions', () => {
      expect(findUserCollapse().text()).toContain('User access');
      expect(findUserCollapse().text()).toContain('User: Read');

      expect(findUserCollapse().text()).toContain('Projects');
      expect(findUserCollapse().text()).toContain('Project: Read contributed');
    });

    it('renders placeholder when only one type of scope is present', () => {
      createComponent({
        scopes: [mockGranularGroupScope],
      });

      expect(findUserToggleButton().text()).toContain('User permissions (0)');

      expect(findUserCollapse().text()).toContain('No resources added');
    });
  });
});
