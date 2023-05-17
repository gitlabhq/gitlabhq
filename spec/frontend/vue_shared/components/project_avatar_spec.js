import { GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

const defaultProps = {
  projectName: 'GitLab',
};

describe('ProjectAvatar', () => {
  let wrapper;

  const findGlAvatar = () => wrapper.findComponent(GlAvatar);

  const createComponent = ({ props, attrs } = {}) => {
    wrapper = shallowMount(ProjectAvatar, { propsData: { ...defaultProps, ...props }, attrs });
  };

  it('renders GlAvatar with correct props', () => {
    createComponent();

    const avatar = findGlAvatar();
    expect(avatar.exists()).toBe(true);
    expect(avatar.props()).toMatchObject({
      alt: defaultProps.projectName,
      entityName: defaultProps.projectName,
      size: 32,
      src: '',
      fallbackOnError: true,
    });
  });

  describe('with `size` prop', () => {
    it('renders GlAvatar with specified `size` prop', () => {
      const mockSize = 48;
      createComponent({ props: { size: mockSize } });

      const avatar = findGlAvatar();
      expect(avatar.props('size')).toBe(mockSize);
    });
  });

  describe('with `projectId` prop', () => {
    const validatorFunc = ProjectAvatar.props.projectId.validator;

    it('prop validators return true for valid types', () => {
      expect(validatorFunc(1)).toBe(true);
      expect(validatorFunc('gid://gitlab/Project/1')).toBe(true);
    });

    it('prop validators return false for invalid types', () => {
      expect(validatorFunc('1')).toBe(false);
    });

    it('renders GlAvatar with `entityId` 0 when `projectId` is not informed', () => {
      createComponent({ props: { projectId: undefined } });

      const avatar = findGlAvatar();
      expect(avatar.props('entityId')).toBe(0);
    });

    it('renders GlAvatar with specified `entityId` when `projectId` is a Number', () => {
      const mockProjectId = 1;
      createComponent({ props: { projectId: mockProjectId } });

      const avatar = findGlAvatar();
      expect(avatar.props('entityId')).toBe(mockProjectId);
    });

    it('renders GlAvatar with specified `entityId` when `projectId` is a gid String', () => {
      const mockProjectId = 'gid://gitlab/Project/1';
      createComponent({ props: { projectId: mockProjectId } });

      const avatar = findGlAvatar();
      expect(avatar.props('entityId')).toBe(1);
    });
  });

  describe('with `projectAvatarUrl` prop', () => {
    it('renders GlAvatar with specified `src` prop', () => {
      const mockProjectAvatarUrl = 'https://gitlab.com';
      createComponent({ props: { projectAvatarUrl: mockProjectAvatarUrl } });

      const avatar = findGlAvatar();
      expect(avatar.props('src')).toBe(mockProjectAvatarUrl);
    });
  });

  describe.each`
    alt
    ${''}
    ${'custom-alt'}
  `('when `alt` prop is "$alt"', ({ alt }) => {
    it('renders GlAvatar with specified `alt` attribute', () => {
      createComponent({ props: { alt } });

      const avatar = findGlAvatar();
      expect(avatar.props('alt')).toBe(alt);
    });
  });
});
