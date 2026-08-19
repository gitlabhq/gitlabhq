import { GlLink, GlButtonGroup } from '@gitlab/ui';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitNavigation from '~/rapid_diffs/app/compare_versions/commit_navigation.vue';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

jest.mock('~/behaviors/shortcuts/shortcuts_disabled');

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
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findNavButtons = () => wrapper.findByTestId('commit-nav-buttons');
  const findPrevButton = () => wrapper.findByTestId('prev-commit-button');
  const findNextButton = () => wrapper.findByTestId('next-commit-button');
  const findPrevDisabledTooltip = () => wrapper.findByTestId('prev-commit-disabled-tooltip');
  const findNextDisabledTooltip = () => wrapper.findByTestId('next-commit-disabled-tooltip');

  beforeEach(() => {
    keyboardShortcutsDisabled.mockReturnValue(false);
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
  describe('disabled-button tooltip overlay', () => {
    it('renders a tooltip overlay on the disabled previous button at the first commit', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: null, next_commit_id: 'next456' },
      });

      expect(findPrevDisabledTooltip().exists()).toBe(true);
      expect(findPrevDisabledTooltip().attributes('title')).toBe("You're at the first commit");
      expect(findNextDisabledTooltip().exists()).toBe(false);
    });

    it('renders a tooltip overlay on the disabled next button at the last commit', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: 'prev123', next_commit_id: null },
      });

      expect(findNextDisabledTooltip().exists()).toBe(true);
      expect(findNextDisabledTooltip().attributes('title')).toBe("You're at the last commit");
      expect(findPrevDisabledTooltip().exists()).toBe(false);
    });

    it('renders no tooltip overlay when both buttons are enabled', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: 'prev123', next_commit_id: 'next456' },
      });

      expect(findPrevDisabledTooltip().exists()).toBe(false);
      expect(findNextDisabledTooltip().exists()).toBe(false);
    });
  });

  describe('aria-keyshortcuts', () => {
    const commitWithNeighbors = {
      ...baseCommit,
      prev_commit_id: 'prev123',
      next_commit_id: 'next456',
    };

    it('sets aria-keyshortcuts on both enabled buttons', () => {
      createComponent({ commit: commitWithNeighbors });

      expect(findPrevButton().attributes('aria-keyshortcuts')).toBe('x');
      expect(findNextButton().attributes('aria-keyshortcuts')).toBe('c');
    });

    it('omits aria-keyshortcuts on a disabled button', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: null, next_commit_id: 'next456' },
      });

      expect(findPrevButton().attributes('aria-keyshortcuts')).toBeUndefined();
      expect(findNextButton().attributes('aria-keyshortcuts')).toBe('c');
    });

    it('omits aria-keyshortcuts when shortcuts are disabled', () => {
      keyboardShortcutsDisabled.mockReturnValue(true);
      createComponent({ commit: commitWithNeighbors });

      expect(findPrevButton().attributes('aria-keyshortcuts')).toBeUndefined();
      expect(findNextButton().attributes('aria-keyshortcuts')).toBeUndefined();
    });
  });

  describe('tooltip shortcut hint', () => {
    const tooltipValue = (buttonWrapper) => getBinding(buttonWrapper.element, 'gl-tooltip').value;

    const commitWithNeighbors = {
      ...baseCommit,
      prev_commit_id: 'prev123',
      next_commit_id: 'next456',
    };

    it('renders a kbd shortcut hint in enabled button tooltips', () => {
      createComponent({ commit: commitWithNeighbors });

      expect(tooltipValue(findPrevButton())).toBe(
        'Previous commit <kbd class="flat gl-ml-1" aria-hidden="true">x</kbd>',
      );
      expect(tooltipValue(findNextButton())).toBe(
        'Next commit <kbd class="flat gl-ml-1" aria-hidden="true">c</kbd>',
      );
    });

    it('renders plain-text tooltip on a disabled button', () => {
      createComponent({
        commit: { ...baseCommit, prev_commit_id: null, next_commit_id: 'next456' },
      });

      expect(tooltipValue(findPrevButton())).toBe("You're at the first commit");
    });

    it('renders plain-text tooltips when shortcuts are disabled', () => {
      keyboardShortcutsDisabled.mockReturnValue(true);
      createComponent({ commit: commitWithNeighbors });

      expect(tooltipValue(findPrevButton())).toBe('Previous commit');
      expect(tooltipValue(findNextButton())).toBe('Next commit');
    });
  });
});
