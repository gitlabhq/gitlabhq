import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import getDiffWithCommit from 'test_fixtures/merge_request_diffs/with_commit.json';
import ReviewTabContainer from '~/add_context_commits_modal/components/review_tab_container.vue';
import CommitItem from '~/diffs/components/commit_item.vue';

describe('ReviewTabContainer', () => {
  let wrapper;
  const { commit } = getDiffWithCommit;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(ReviewTabContainer, {
      propsData: {
        tab: 'commits',
        isLoading: false,
        loadingError: false,
        loadingFailedText: 'Failed to load commits',
        commits: [],
        selectedRow: [],
        ...props,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('shows loading icon when commits are being loaded', () => {
    createWrapper({ isLoading: true });
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('shows loading error text when API call fails', () => {
    createWrapper({ loadingError: true });
    expect(wrapper.text()).toContain('Failed to load commits');
  });

  it('shows "No commits present here" when commits are not present', () => {
    expect(wrapper.text()).toContain('No commits present here');
  });

  it('renders all passed commits as list', () => {
    createWrapper({ commits: [commit] });
    expect(wrapper.findAllComponents(CommitItem).length).toBe(1);
  });
});
