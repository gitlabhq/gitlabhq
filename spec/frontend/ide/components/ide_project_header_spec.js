import { shallowMount } from '@vue/test-utils';
import IDEProjectHeader from '~/ide/components/ide_project_header.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

const mockProject = {
  name: 'test proj',
  avatar_url: 'https://gitlab.com',
  path_with_namespace: 'path/with-namespace',
  web_url: 'https://gitlab.com/project',
};

describe('IDE project header', () => {
  let wrapper;

  const findProjectAvatar = () => wrapper.findComponent(ProjectAvatar);
  const findProjectLink = () => wrapper.find('[data-testid="go-to-project-link"');

  const createComponent = () => {
    wrapper = shallowMount(IDEProjectHeader, { propsData: { project: mockProject } });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders ProjectAvatar with correct props', () => {
      expect(findProjectAvatar().props()).toMatchObject({
        projectName: mockProject.name,
        projectAvatarUrl: mockProject.avatar_url,
      });
    });

    it('renders a link to the project URL', () => {
      const link = findProjectLink();
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(mockProject.web_url);
    });
  });
});
