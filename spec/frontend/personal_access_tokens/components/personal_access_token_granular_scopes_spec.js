import { GlIcon, GlLink, GlButton, GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import PersonalAccessTokenGranularScopes from '~/personal_access_tokens/components/personal_access_token_granular_scopes.vue';
import { mockGranularGroupScope, mockGranularUserScope } from '../mock_data';

describe('PersonalAccessTokenGranularScopes', () => {
  let wrapper;

  const createComponent = ({ scopes = [mockGranularGroupScope] } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenGranularScopes, {
      propsData: { scopes },
    });
  };

  const findProjectAvatar = () => wrapper.findComponent(ProjectAvatar);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findIcons = () => wrapper.findAllComponents(GlIcon);

  const findToggleButtons = () => wrapper.findAllComponents(GlButton);
  const findGroupToggleButton = () => findToggleButtons().at(0);
  const findUserToggleButton = () => findToggleButtons().at(1);

  const findCollapses = () => wrapper.findAllComponents(GlCollapse);
  const findGroupCollapse = () => findCollapses().at(0);
  const findUserCollapse = () => findCollapses().at(1);

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
      expect(findLinks().at(0).attributes('href')).toBe(mockGranularGroupScope.namespace.webUrl);
      expect(findLinks().at(0).text()).toBe(mockGranularGroupScope.namespace.fullName);
    });

    it('renders group icon for namespace', () => {
      expect(findIcons().at(0).props()).toMatchObject({
        name: 'group',
      });
    });

    it('renders multiple namespaces when multiple `SELECTED_MEMBERSHIPS` scopes are provided', () => {
      const multipleScopes = [
        mockGranularGroupScope,
        {
          ...mockGranularGroupScope,
          namespace: {
            id: 'gid://gitlab/Namespaces::ProjectNamespace/1',
            fullName: 'My Project',
            fullPath: 'my-project',
            webUrl: 'https://gitlab.com/projects/my-project',
            avatarUrl: '/avatar.png',
          },
        },
      ];

      createComponent({ scopes: multipleScopes });

      expect(wrapper.findAllComponents(ProjectAvatar)).toHaveLength(2);

      expect(findIcons().at(2).props()).toMatchObject({
        name: 'project',
      });
    });

    it('handles scope without namespace', () => {
      createComponent({ scopes: [{ ...mockGranularGroupScope, namespace: null }] });

      expect(findProjectAvatar().exists()).toBe(false);
    });
  });

  describe('permissions', () => {
    beforeEach(() => {
      createComponent({
        scopes: [mockGranularGroupScope, mockGranularUserScope],
      });
    });

    it('renders group permissions toggle', () => {
      expect(findGroupToggleButton().text()).toContain('Group and project permissions (4)');
    });

    it('renders user permissions toggle', () => {
      expect(findUserToggleButton().text()).toContain('User permissions (2)');
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
