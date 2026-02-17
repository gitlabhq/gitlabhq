import { nextTick } from 'vue';
import { GlPopover, GlAvatar, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitPopover from '~/vue_shared/components/source_viewer/components/commit_popover.vue';

const mockFormat = jest.fn(() => '2 days ago');

jest.mock('~/lib/utils/datetime_utility', () => ({
  getTimeago: jest.fn(() => ({
    format: mockFormat,
  })),
}));

describe('CommitPopover component', () => {
  let wrapper;

  const defaultCommit = {
    sha: 'abc123def456',
    shortId: 'abc123de',
    title: 'Fix bug in feature',
    authorName: 'Test Author',
    authoredDate: '2024-01-15T10:00:00Z',
    webPath: '/project/-/commit/abc123def456',
    authorGravatar: 'https://gravatar.com/avatar/test',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CommitPopover, {
      propsData: {
        popoverTargetId: '123',
        commit: defaultCommit,
        ...props,
      },
    });
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findShaLink = () => wrapper.findByTestId('commit-sha-link');
  const findTitleLink = () => wrapper.findByTestId('commit-title-link');
  const findAuthoredTime = () => wrapper.findByTestId('commit-authored-time');

  describe('rendering', () => {
    beforeEach(() => createComponent());

    it('renders the popover', async () => {
      await nextTick();
      expect(findPopover().exists()).toBe(true);
    });

    it('renders short SHA linking to commit', () => {
      expect(findShaLink().text()).toBe('abc123de');
      expect(findShaLink().attributes('href')).toBe(defaultCommit.webPath);
    });

    it('renders commit title linking to commit', () => {
      expect(wrapper.findComponent(GlTruncate).props('text')).toBe(defaultCommit.title);
      expect(findTitleLink().attributes('href')).toBe(defaultCommit.webPath);
    });

    it('renders author info', () => {
      expect(wrapper.findByTestId('commit-author').text()).toBe(defaultCommit.authorName);
      expect(wrapper.findComponent(GlAvatar).props('src')).toBe(defaultCommit.authorGravatar);
    });

    it('renders authored date with timeago format', () => {
      expect(findAuthoredTime().text()).toBe('Authored 2 days ago');
    });
  });

  describe('authoredText', () => {
    it('passes a Date object to getTimeago().format()', () => {
      createComponent();

      expect(mockFormat).toHaveBeenCalledWith(expect.any(Date));
    });
  });

  describe('with author object', () => {
    const author = { name: 'Author Name', avatarUrl: 'https://example.com/avatar.png' };

    beforeEach(() => {
      createComponent({ commit: { ...defaultCommit, author, authorGravatar: null } });
    });

    it('prefers author object over flat properties', () => {
      expect(wrapper.findByTestId('commit-author').text()).toBe(author.name);
      expect(wrapper.findComponent(GlAvatar).props('src')).toBe(author.avatarUrl);
    });
  });

  describe('fallbacks', () => {
    it('uses commitUrl when webPath is unavailable', () => {
      createComponent({ commit: { ...defaultCommit, webPath: null, commitUrl: '/fallback' } });

      expect(findShaLink().attributes('href')).toBe('/fallback');
    });
  });
});
