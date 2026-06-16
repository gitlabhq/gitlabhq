import { GlLink, GlButtonGroup } from '@gitlab/ui';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitNavigation from '~/rapid_diffs/app/compare_versions/commit_navigation.vue';

describe('CommitNavigation', () => {
  let wrapper;

  const baseCommit = {
    id: 'abc123full',
    short_id: 'abc123',
    commit_url: '/project/-/commit/abc123full',
    diff_refs: { base_sha: 'p', start_sha: 'p', head_sha: 'abc123full' },
  };

  const createComponent = ({ commit = baseCommit } = {}) => {
    wrapper = shallowMountExtended(CommitNavigation, {
      propsData: { commit },
    });
  };

  const findNavButtons = () => wrapper.findByTestId('commit-nav-buttons');
  const findPrevButton = () => wrapper.findByTestId('prev-commit-button');
  const findNextButton = () => wrapper.findByTestId('next-commit-button');

  beforeEach(() => {
    setWindowLocation(`${TEST_HOST}/?commit_id=abc123full`);
  });

  it('shows commit short_id with link', () => {
    createComponent();

    const link = wrapper.findComponent(GlLink);
    expect(link.attributes('href')).toBe('/project/-/commit/abc123full');
    expect(link.text()).toBe('abc123');
  });

  it('shows latest version button', () => {
    createComponent();

    const latestButton = wrapper.findByTestId('show-latest-version-button');
    expect(latestButton.exists()).toBe(true);
    expect(latestButton.attributes('href')).toBeDefined();
  });

  describe('without neighbor commits', () => {
    it('does not render navigation buttons', () => {
      createComponent();

      expect(findNavButtons().exists()).toBe(false);
    });
  });

  describe('with neighbor commits', () => {
    const commitWithNeighbors = {
      ...baseCommit,
      prev_commit_id: 'prev123',
      next_commit_id: 'next456',
    };

    it('renders the navigation button group', () => {
      createComponent({ commit: commitWithNeighbors });

      expect(findNavButtons().exists()).toBe(true);
      expect(wrapper.findComponent(GlButtonGroup).exists()).toBe(true);
    });

    it('sets correct href on previous button', () => {
      createComponent({ commit: commitWithNeighbors });

      expect(findPrevButton().attributes('href')).toBe(`${TEST_HOST}/?commit_id=prev123`);
    });

    it('sets correct href on next button', () => {
      createComponent({ commit: commitWithNeighbors });

      expect(findNextButton().attributes('href')).toBe(`${TEST_HOST}/?commit_id=next456`);
    });

    it('enables both buttons when both neighbors exist', () => {
      createComponent({ commit: commitWithNeighbors });

      expect(findPrevButton().attributes('disabled')).toBeUndefined();
      expect(findNextButton().attributes('disabled')).toBeUndefined();
    });

    it('shows button group when only prev_commit_id exists', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: 'prev123', next_commit_id: null },
      });

      expect(findNavButtons().exists()).toBe(true);
    });

    it('shows button group when only next_commit_id exists', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: null, next_commit_id: 'next456' },
      });

      expect(findNavButtons().exists()).toBe(true);
    });
  });

  describe('at first commit', () => {
    const firstCommit = {
      ...baseCommit,
      prev_commit_id: null,
      next_commit_id: 'next456',
    };

    it('disables previous button', () => {
      createComponent({ commit: firstCommit });

      expect(findPrevButton().attributes('disabled')).toBeDefined();
    });

    it('enables next button', () => {
      createComponent({ commit: firstCommit });

      expect(findNextButton().attributes('disabled')).toBeUndefined();
    });

    it('sets first commit aria-label on previous button', () => {
      createComponent({ commit: firstCommit });

      expect(findPrevButton().attributes('aria-label')).toBe("You're at the first commit");
    });
  });

  describe('at last commit', () => {
    const lastCommit = {
      ...baseCommit,
      prev_commit_id: 'prev123',
      next_commit_id: null,
    };

    it('enables previous button', () => {
      createComponent({ commit: lastCommit });

      expect(findPrevButton().attributes('disabled')).toBeUndefined();
    });

    it('disables next button', () => {
      createComponent({ commit: lastCommit });

      expect(findNextButton().attributes('disabled')).toBeDefined();
    });

    it('sets last commit aria-label on next button', () => {
      createComponent({ commit: lastCommit });

      expect(findNextButton().attributes('aria-label')).toBe("You're at the last commit");
    });
  });
});
