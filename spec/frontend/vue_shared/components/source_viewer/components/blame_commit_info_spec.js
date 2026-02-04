import { GlButton, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameCommitInfo from '~/vue_shared/components/source_viewer/components/blame_commit_info.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

describe('BlameCommitInfo component', () => {
  let wrapper;

  const defaultCommit = {
    title: 'Commit title',
    message: 'Commit message',
    authoredDate: '2024-01-01',
    authorGravatar: 'https://gravatar.com/avatar',
    webPath: '/commit/abc123',
    parentSha: 'parent123',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BlameCommitInfo, {
      propsData: {
        commit: defaultCommit,
        ...props,
      },
    });
  };

  const findTimeagoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findUserAvatar = () => wrapper.findComponent(UserAvatarImage);
  const findCommitLink = () => wrapper.findComponent(GlLink);
  const findPreviousBlameButton = () => wrapper.findComponent(GlButton);

  describe('commit information display', () => {
    beforeEach(() => createComponent());

    it('renders commit time', () => {
      expect(findTimeagoTooltip().props('time')).toBe(defaultCommit.authoredDate);
    });

    it('renders author avatar', () => {
      expect(findUserAvatar().props('imgSrc')).toBe(defaultCommit.authorGravatar);
    });

    it('renders commit link with correct href', () => {
      expect(findCommitLink().attributes('href')).toBe(defaultCommit.webPath);
    });
  });

  describe('avatar fallbacks', () => {
    it.each([
      ['authorGravatar', { authorGravatar: 'gravatar-url' }, 'gravatar-url'],
      ['avatarUrl', { avatarUrl: 'avatar-url' }, 'avatar-url'],
    ])('uses %s when available', (_, commitOverrides, expectedUrl) => {
      createComponent({ commit: { ...defaultCommit, authorGravatar: null, ...commitOverrides } });

      expect(findUserAvatar().props('imgSrc')).toContain(expectedUrl);
    });
  });

  describe('commit URL fallbacks', () => {
    it.each([
      ['webPath', { webPath: '/web/path' }, '/web/path'],
      ['commitUrl', { webPath: null, commitUrl: '/commit/url' }, '/commit/url'],
    ])('uses %s when available', (_, commitOverrides, expectedUrl) => {
      createComponent({ commit: { ...defaultCommit, ...commitOverrides } });

      expect(findCommitLink().attributes('href')).toBe(expectedUrl);
    });
  });

  describe('empty commit message styling', () => {
    it('applies italic class when commit has no message or title', () => {
      createComponent({ commit: { ...defaultCommit, message: null, title: null } });

      expect(findCommitLink().classes()).toContain('gl-italic');
    });

    it('does not apply italic class when commit has message', () => {
      createComponent();

      expect(findCommitLink().classes()).not.toContain('gl-italic');
    });
  });

  describe('previous blame button', () => {
    it('renders when previousPath, parentSha, and projectPath are provided', () => {
      createComponent({
        previousPath: 'old/file.js',
        projectPath: 'gitlab-org/gitlab',
      });

      expect(findPreviousBlameButton().attributes('href')).toBe(
        '/gitlab-org/gitlab/-/blob/parent123/old/file.js?blame=1',
      );
    });

    it.each([
      ['previousPath', { projectPath: 'gitlab-org/gitlab' }],
      ['projectPath', { previousPath: 'old/file.js' }],
      [
        'parentSha',
        {
          previousPath: 'old/file.js',
          projectPath: 'gitlab-org/gitlab',
          commit: { ...defaultCommit, parentSha: null },
        },
      ],
    ])('does not render when %s is missing', (_, props) => {
      createComponent(props);

      expect(findPreviousBlameButton().exists()).toBe(false);
    });
  });
});
