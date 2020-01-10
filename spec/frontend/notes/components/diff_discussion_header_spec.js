import { mount } from '@vue/test-utils';

import createStore from '~/notes/stores';
import diffDiscussionHeader from '~/notes/components/diff_discussion_header.vue';

import { discussionMock } from '../../../javascripts/notes/mock_data';
import mockDiffFile from '../../diffs/mock_data/diff_discussions';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

describe('diff_discussion_header component', () => {
  let store;
  let wrapper;

  preloadFixtures(discussionWithTwoUnresolvedNotes);

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();

    wrapper = mount(diffDiscussionHeader, {
      store,
      propsData: { discussion: discussionMock },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render user avatar', () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = mockDiffFile;
    discussion.diff_discussion = true;

    wrapper.setProps({ discussion });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find('.user-avatar-link').exists()).toBe(true);
    });
  });

  describe('action text', () => {
    const commitId = 'razupaltuff';
    const truncatedCommitId = commitId.substr(0, 8);
    let commitElement;

    beforeEach(done => {
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

      wrapper.vm
        .$nextTick()
        .then(() => {
          commitElement = wrapper.find('.commit-sha');
        })
        .then(done)
        .catch(done.fail);
    });

    describe('for diff threads without a commit id', () => {
      it('should show started a thread on the diff text', done => {
        Object.assign(wrapper.vm.discussion, {
          for_commit: false,
          commit_id: null,
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain('started a thread on the diff');

          done();
        });
      });

      it('should show thread on older version text', done => {
        Object.assign(wrapper.vm.discussion, {
          for_commit: false,
          commit_id: null,
          active: false,
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain('started a thread on an old version of the diff');

          done();
        });
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
      it('should display started thread on commit header', done => {
        wrapper.vm.discussion.for_commit = false;

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain(`started a thread on commit ${truncatedCommitId}`);

          expect(commitElement).not.toBe(null);

          done();
        });
      });

      it('should display outdated change on commit header', done => {
        wrapper.vm.discussion.for_commit = false;
        wrapper.vm.discussion.active = false;

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain(
            `started a thread on an outdated change in commit ${truncatedCommitId}`,
          );

          expect(commitElement).not.toBe(null);

          done();
        });
      });
    });
  });
});
