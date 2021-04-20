import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommitBlock from '~/jobs/components/commit_block.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('Commit block', () => {
  let wrapper;

  const commit = {
    short_id: '1f0fb84f',
    id: '1f0fb84fb6770d74d97eee58118fd3909cd4f48c',
    commit_path: 'commit/1f0fb84fb6770d74d97eee58118fd3909cd4f48c',
    title: 'Update README.md',
  };

  const mergeRequest = {
    iid: '!21244',
    path: 'merge_requests/21244',
  };

  const findCommitSha = () => wrapper.findByTestId('commit-sha');
  const findLinkSha = () => wrapper.findByTestId('link-commit');

  const mountComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(CommitBlock, {
        propsData: {
          commit,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without merge request', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders pipeline short sha link', () => {
      expect(findCommitSha().attributes('href')).toBe(commit.commit_path);
      expect(findCommitSha().text()).toBe(commit.short_id);
    });

    it('renders clipboard button', () => {
      expect(wrapper.findComponent(ClipboardButton).attributes('text')).toBe(commit.id);
    });

    it('renders git commit title', () => {
      expect(wrapper.text()).toContain(commit.title);
    });

    it('does not render merge request', () => {
      expect(findLinkSha().exists()).toBe(false);
    });
  });

  describe('with merge request', () => {
    it('renders merge request link and reference', () => {
      mountComponent({ mergeRequest });

      expect(findLinkSha().attributes('href')).toBe(mergeRequest.path);
      expect(findLinkSha().text()).toBe(`!${mergeRequest.iid}`);
    });
  });
});
