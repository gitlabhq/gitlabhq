import { nextTick } from 'vue';
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import diffDiscussionHeader from '~/notes/components/diff_discussion_header.vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import createStore from '~/notes/stores';

import mockDiffFile from 'jest/diffs/mock_data/diff_discussions';
import { discussionMock } from '../mock_data';

describe('diff_discussion_header component', () => {
  let store;
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(diffDiscussionHeader, {
      store,
      propsData: {
        discussion: discussionMock,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();

    createComponent({ propsData: { discussion: discussionMock } });
  });

  describe('Avatar', () => {
    const firstNoteAuthor = discussionMock.notes[0].author;
    const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
    const findAvatar = () => wrapper.findComponent(GlAvatar);

    it('should render user avatar and user avatar link with popover support', () => {
      expect(findAvatar().exists()).toBe(true);

      const avatarLink = findAvatarLink();
      expect(avatarLink.exists()).toBe(true);
      expect(avatarLink.classes()).toContain('js-user-link');
      expect(avatarLink.attributes()).toMatchObject({
        href: firstNoteAuthor.path,
        'data-user-id': `${firstNoteAuthor.id}`,
        'data-username': `${firstNoteAuthor.username}`,
      });
    });

    it('renders avatar of the first note author', () => {
      expect(findAvatar().props('src')).toBe(firstNoteAuthor.avatar_url);
      expect(findAvatar().props('alt')).toBe(firstNoteAuthor.name);
      expect(findAvatar().props('size')).toBe(32);
    });
  });

  describe('action text', () => {
    const commitId = 'razupaltuff';
    const truncatedCommitId = commitId.substr(0, 8);
    let commitElement;

    beforeEach(async () => {
      store.state.diffs = {
        projectPath: 'something',
      };

      createComponent({
        propsData: {
          discussion: {
            ...discussionMock,
            for_commit: true,
            commit_id: commitId,
            diff_discussion: true,
            diff_file: {
              ...mockDiffFile,
            },
          },
        },
      });

      await nextTick();
      commitElement = wrapper.find('.commit-sha');
    });

    describe('for diff threads without a commit id', () => {
      it('should show started a thread on the diff text', async () => {
        createComponent({
          propsData: {
            discussion: {
              ...discussionMock,
              diff_discussion: true,
              for_commit: false,
              commit_id: null,
            },
          },
        });

        await nextTick();
        expect(wrapper.text()).toContain('started a thread on the diff');
      });

      it('should show thread on older version text', async () => {
        createComponent({
          propsData: {
            discussion: {
              ...discussionMock,
              diff_discussion: true,
              for_commit: false,
              commit_id: null,
              active: false,
            },
          },
        });

        await nextTick();
        expect(wrapper.text()).toContain('started a thread on an old version of the diff');
      });
    });

    describe('for commit threads', () => {
      it('should display a monospace started a thread on commit', () => {
        expect(wrapper.text()).toContain(`started a thread on commit ${truncatedCommitId}`);
        expect(commitElement.exists()).toBe(true);
        expect(commitElement.text()).toContain(truncatedCommitId);
      });
    });

    describe('for diff thread with a commit id', () => {
      it('should display started thread on commit header', async () => {
        createComponent({
          propsData: {
            discussion: {
              ...discussionMock,
              diff_discussion: true,
              for_commit: false,
              commit_id: commitId,
            },
          },
        });

        await nextTick();
        expect(wrapper.text()).toContain(`started a thread on commit ${truncatedCommitId}`);

        expect(commitElement).not.toBe(null);
      });

      it('should display outdated change on commit header', async () => {
        createComponent({
          propsData: {
            discussion: {
              ...discussionMock,
              diff_discussion: true,
              for_commit: false,
              commit_id: commitId,
              active: false,
            },
          },
        });

        await nextTick();
        expect(wrapper.text()).toContain(
          `started a thread on an outdated change in commit ${truncatedCommitId}`,
        );

        expect(commitElement).not.toBe(null);
      });
    });
  });

  describe('replies toggle', () => {
    it('renders replies toggle', () => {
      createComponent();
      expect(wrapper.findComponent(ToggleRepliesWidget).exists()).toBe(true);
      expect(wrapper.findComponent(ToggleRepliesWidget).props()).toMatchObject({
        collapsed: false,
        replies: discussionMock.notes,
      });
    });

    it('skips system notes', () => {
      createComponent({
        propsData: {
          discussion: {
            ...discussionMock,
            notes: [...discussionMock.notes, { system: true }],
          },
        },
      });
      expect(wrapper.findComponent(ToggleRepliesWidget).props('replies')).toStrictEqual(
        discussionMock.notes,
      );
    });

    it('passes collapsed state', () => {
      createComponent({
        propsData: {
          discussion: {
            ...discussionMock,
            expanded: false,
          },
        },
      });
      expect(wrapper.findComponent(ToggleRepliesWidget).props('collapsed')).toBe(true);
    });
  });
});
