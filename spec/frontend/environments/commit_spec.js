import { GlAvatar } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Commit from '~/environments/components/commit.vue';
import { resolvedEnvironment } from './graphql/mock_data';

describe('~/environments/components/commit.vue', () => {
  let commit;
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatar);

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
      expect(findAvatar().props('src')).toBe(commit.author.avatarUrl);
    });

    it('links the commit title to the commit', () => {
      const message = wrapper.findByRole('link', { name: commit.title });

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
      expect(findAvatar().props('src')).toBe(commit.authorGravatarUrl);
    });

    it('displays the commit title', () => {
      const title = wrapper.findByRole('link', { name: commit.title });

      expect(title.attributes('href')).toBe(commit.commitPath);
    });
  });

  describe('from graphql', () => {
    beforeEach(() => {
      commit = { ...commit, webPath: commit.commitPath, commitPath: null };
      wrapper = createWrapper();
    });

    it('links to the user profile', () => {
      const link = wrapper.findByRole('link', { name: commit.author.name });
      expect(link.attributes('href')).toBe(commit.author.path);
    });

    it('displays the user avatar', () => {
      expect(findAvatar().props('src')).toBe(commit.author.avatarUrl);
    });

    it('links the commit title to the commit', () => {
      const message = wrapper.findByRole('link', { name: commit.title });

      expect(message.attributes('href')).toBe(commit.webPath);
    });
  });
});
