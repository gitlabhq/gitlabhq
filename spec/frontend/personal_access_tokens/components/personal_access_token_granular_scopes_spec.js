import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import PersonalAccessTokenGranularScopes from '~/personal_access_tokens/components/personal_access_token_granular_scopes.vue';
import {
  mockGranularGroupScope,
  mockGranularInstanceScope,
  mockGranularUserScope,
} from '../mock_data';

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

  beforeEach(() => {
    createComponent();
  });

  describe('permissions text', () => {
    it('renders group permissions text when scoped on group', () => {
      expect(wrapper.text()).toContain('Group and project permissions');
    });

    it('renders user permissions text when scoped on user', () => {
      createComponent({
        scopes: [mockGranularUserScope],
      });

      expect(wrapper.text()).toContain('User permissions');
    });

    it('renders instance permissions text when scoped on instance', () => {
      createComponent({
        scopes: [mockGranularInstanceScope],
      });

      expect(wrapper.text()).toContain('Instance permissions');
    });
  });

  describe('group access descriptions', () => {
    it('renders personal projects description', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, access: 'PERSONAL_PROJECTS' }],
      });

      expect(wrapper.text()).toContain('Only personal projects');
    });

    it('renders selected memberships description', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, access: 'SELECTED_MEMBERSHIPS' }],
      });

      expect(wrapper.text()).toContain("Only specific group or projects that I'm a member of");
    });

    it('renders all memberships description', () => {
      createComponent({
        scopes: [{ ...mockGranularGroupScope, access: 'ALL_MEMBERSHIPS' }],
      });

      expect(wrapper.text()).toContain("All groups and projects that I'm a member of");
    });
  });

  describe('permissions grouping', () => {
    it('groups permissions by resource and formats them', () => {
      expect(wrapper.text()).toContain('read, write: project');
      expect(wrapper.text()).toContain('admin: group');
    });

    it('shows check icon', () => {
      expect(findIcons().at(1).props()).toMatchObject({
        name: 'check-sm',
        variant: 'success',
      });
    });
  });

  describe('namespace', () => {
    it('renders namespace when scoped on group', () => {
      createComponent();

      expect(findProjectAvatar().exists()).toBe(true);
      expect(findProjectAvatar().props()).toMatchObject({
        projectId: mockGranularGroupScope.namespace.id,
        projectName: mockGranularGroupScope.namespace.fullName,
        projectAvatarUrl: mockGranularGroupScope.namespace.avatarUrl,
        size: 24,
      });
    });

    it('renders link to namespace', () => {
      createComponent();

      expect(findLinks().at(0).attributes('href')).toBe(mockGranularGroupScope.namespace.webUrl);
      expect(findLinks().at(0).text()).toBe(mockGranularGroupScope.namespace.fullName);
    });

    it('renders group icon for namespace', () => {
      createComponent();

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

      expect(findIcons().at(1).props()).toMatchObject({
        name: 'project',
      });
    });

    it('handles scope without namespace', () => {
      createComponent({ scopes: [{ ...mockGranularGroupScope, namespace: null }] });

      expect(findProjectAvatar().exists()).toBe(false);
    });
  });

  describe('multiple scopes', () => {
    it('renders multiple scopes', () => {
      createComponent({
        scopes: [mockGranularGroupScope, mockGranularUserScope, mockGranularInstanceScope],
      });

      expect(wrapper.text()).toContain('Group and project permissions');
      expect(wrapper.text()).toContain('read, write: project');
      expect(wrapper.text()).toContain('admin: group');

      expect(wrapper.text()).toContain('User permissions');
      expect(wrapper.text()).toContain('read, create: profile');

      expect(wrapper.text()).toContain('Instance permissions');
      expect(wrapper.text()).toContain('read, create: admin member role');
    });
  });
});
