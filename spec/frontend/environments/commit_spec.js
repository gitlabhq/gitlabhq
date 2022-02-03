import { mountExtended } from 'helpers/vue_test_utils_helper';
import Commit from '~/environments/components/commit.vue';
import { resolvedEnvironment } from './graphql/mock_data';

describe('~/environments/components/commit.vue', () => {
  let commit;
  let wrapper;

  beforeEach(() => {
    commit = resolvedEnvironment.lastDeployment.commit;
  });

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(Commit, {
      propsData: {
        commit,
        ...propsData,
      },
    });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('with gitlab user', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('links to the user profile', () => {
      const link = wrapper.findByRole('link', { name: commit.author.name });
      expect(link.attributes('href')).toBe(commit.author.path);
    });

    it('displays the user avatar', () => {
      const avatar = wrapper.findByRole('img', { name: 'avatar' });
      expect(avatar.attributes('src')).toBe(commit.author.avatarUrl);
    });

    it('links the commit message to the commit', () => {
      const message = wrapper.findByRole('link', { name: commit.message });

      expect(message.attributes('href')).toBe(commit.commitPath);
    });
  });
  describe('without gitlab user', () => {
    beforeEach(() => {
      commit = {
        ...commit,
        author: null,
      };
      wrapper = createWrapper();
    });

    it('links to the user profile', () => {
      const link = wrapper.findByRole('link', { name: commit.authorName });
      expect(link.attributes('href')).toBe(`mailto:${commit.authorEmail}`);
    });

    it('displays the user avatar', () => {
      const avatar = wrapper.findByRole('img', { name: 'avatar' });
      expect(avatar.attributes('src')).toBe(commit.authorGravatarUrl);
    });

    it('displays the commit message', () => {
      const message = wrapper.findByRole('link', { name: commit.message });

      expect(message.attributes('href')).toBe(commit.commitPath);
    });
  });
});
