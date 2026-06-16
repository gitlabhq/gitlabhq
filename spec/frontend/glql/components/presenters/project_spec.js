import { GlAvatarLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectPresenter from '~/glql/components/presenters/project.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { MOCK_PROJECT } from '../../mock_data';

describe('ProjectPresenter', () => {
  let wrapper;

  const MOCK_PROJECT_FULL = {
    ...MOCK_PROJECT,
    id: 'gid://gitlab/Project/42',
    name: 'GitLab Test',
    avatarUrl: 'https://gitlab.example.com/uploads/-/system/project/avatar/42/logo.png',
  };

  const createWrapper = (data) => {
    wrapper = shallowMountExtended(ProjectPresenter, {
      propsData: { data },
    });
  };

  const findLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(ProjectAvatar);

  describe('with a fully populated project', () => {
    beforeEach(() => {
      createWrapper(MOCK_PROJECT_FULL);
    });

    it('links to the project webPath', () => {
      expect(findLink().attributes('href')).toBe(MOCK_PROJECT_FULL.webPath);
    });

    it('uses the project name as the visible label', () => {
      expect(findLink().text()).toBe(MOCK_PROJECT_FULL.name);
    });

    it('uses the full nameWithNamespace as the link title tooltip', () => {
      expect(findLink().attributes('title')).toBe(MOCK_PROJECT_FULL.nameWithNamespace);
    });

    it('passes id, name and avatarUrl through to ProjectAvatar', () => {
      const avatar = findAvatar();
      expect(avatar.props('projectId')).toBe(MOCK_PROJECT_FULL.id);
      expect(avatar.props('projectName')).toBe(MOCK_PROJECT_FULL.name);
      expect(avatar.props('projectAvatarUrl')).toBe(MOCK_PROJECT_FULL.avatarUrl);
      expect(avatar.props('size')).toBe(24);
    });

    it('marks the avatar as decorative so the link is not announced twice', () => {
      expect(findAvatar().props('alt')).toBe('');
    });
  });

  describe('fallbacks when project fields are missing', () => {
    it('falls back to nameWithNamespace for the project name when name is absent', () => {
      createWrapper(MOCK_PROJECT);

      expect(findLink().text()).toBe(MOCK_PROJECT.nameWithNamespace);
      expect(findAvatar().props('projectName')).toBe(MOCK_PROJECT.nameWithNamespace);
    });

    it('falls back to fullPath when nameWithNamespace is also absent', () => {
      createWrapper({ ...MOCK_PROJECT, nameWithNamespace: undefined });

      expect(findLink().text()).toBe(MOCK_PROJECT.fullPath);
      expect(findAvatar().props('projectName')).toBe(MOCK_PROJECT.fullPath);
    });
  });
});
