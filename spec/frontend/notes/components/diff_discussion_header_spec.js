import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import diffDiscussionHeader from '~/notes/components/diff_discussion_header.vue';
import createStore from '~/notes/stores';

import mockDiffFile from 'jest/diffs/mock_data/diff_discussions';
import { discussionMock } from '../mock_data';

describe('diff_discussion_header component', () => {
  let store;
  let wrapper;

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();

    wrapper = shallowMount(diffDiscussionHeader, {
      store,
      propsData: { discussion: discussionMock },
    });
  });

  describe('Avatar', () => {
    const firstNoteAuthor = discussionMock.notes[0].author;
    const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
    const findAvatar = () => wrapper.findComponent(GlAvatar);

    it('should render user avatar and user avatar link', () => {
      expect(findAvatar().exists()).toBe(true);
      expect(findAvatarLink().exists()).toBe(true);
    });

    it('renders avatar of the first note author', () => {
      const props = findAvatar().props();

      expect(props).toMatchObject({
        src: firstNoteAuthor.avatar_url,
        alt: firstNoteAuthor.name,
        size: 32,
      });
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

      wrapper.setProps({
        discussion: {
          ...discussionMock,
          for_commit: true,
          commit_id: commitId,
          diff_discussion: true,
          diff_file: {
            ...mockDiffFile,
          },
        },
      });

      await nextTick();
      commitElement = wrapper.find('.commit-sha');
    });

    describe('for diff threads without a commit id', () => {
      it('should show started a thread on the diff text', async () => {
        Object.assign(wrapper.vm.discussion, {
          for_commit: false,
          commit_id: null,
        });

        await nextTick();
        expect(wrapper.text()).toContain('started a thread on the diff');
      });

      it('should show thread on older version text', async () => {
        Object.assign(wrapper.vm.discussion, {
          for_commit: false,
          commit_id: null,
          active: false,
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
        wrapper.vm.discussion.for_commit = false;

        await nextTick();
        expect(wrapper.text()).toContain(`started a thread on commit ${truncatedCommitId}`);

        expect(commitElement).not.toBe(null);
      });

      it('should display outdated change on commit header', async () => {
        wrapper.vm.discussion.for_commit = false;
        wrapper.vm.discussion.active = false;

        await nextTick();
        expect(wrapper.text()).toContain(
          `started a thread on an outdated change in commit ${truncatedCommitId}`,
        );

        expect(commitElement).not.toBe(null);
      });
    });
  });
});
